import Combine
import Coordinator
import UIKit
import ViewModel

protocol TorrentListViewProvider: AnyObject {
    func previewForItem(at index: Int) -> UIViewController?
    func contextMenuForItem(at index: Int) -> UIMenu?
    func commitPreviewForItem(at index: Int)
    func didDismissPreviewForItem(at index: Int)
    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration?
    func trailingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration?
}

// swiftlint:disable:next line_length
final class TorrentListViewController<VM: ViewModel>: PresentableTableViewController, UISearchResultsUpdating where VM.ViewEvent == TorrentListViewEvent, VM.ViewState == TorrentListViewState {
    private enum Section {
        case main
    }

    private class DataSource: UITableViewDiffableDataSource<Section, TorrentListItem> {
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
    }

    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: DataSource!
    fileprivate var applySnapshotInBackground = true
    weak var provider: TorrentListViewProvider?
    private lazy var statusView = StatusView()

    private lazy var settingsBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped(_:))
        )
    }()

    private lazy var selectBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            title: "Select",
            style: .plain,
            target: self,
            action: #selector(selectButtonTapped(_:))
        )
    }()

    private lazy var doneBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(_:)))
    }()

    private lazy var addBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped(_:))
        )
    }()

    private lazy var filterBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: nil,
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped(_:))
        )
    }()

    private lazy var resumeBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "play.circle"),
            style: .plain,
            target: self,
            action: #selector(resumeButtonTapped(_:))
        )
    }()

    private lazy var pauseBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "pause.circle"),
            style: .plain,
            target: self,
            action: #selector(pauseButtonTapped(_:))
        )
    }()

    private lazy var removeBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "trash.circle"),
            style: .plain,
            target: self,
            action: #selector(removeButtonTapped(_:))
        )
    }()

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped(_:))
        )
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    private lazy var activityView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    private lazy var emptyStateView: UIView = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.text = "No Torrents"
        label.textColor = .placeholderText
        return label
    }()

    // MARK: Initialization

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .plain)
        viewModel.state.title.sink { [weak self] in self?.title = $0 }.store(in: &cancellables)
        navigationItem.searchController = searchController
        configureNormalBarButtonItems()
        configureNormalToolbarItems()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()

        activityView.startAnimating()
        tableView.addSubview(activityView)

        emptyStateView.isHidden = true
        tableView.addSubview(emptyStateView)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        statusView.configure(download: viewModel.state.totalDownloadSpeed, upload: viewModel.state.totalUploadSpeed)

        if viewModel.state.showFilterButton {
            viewModel.state.hasActiveFilters
                .sink { [weak self] in
                    self?.filterBarButtonItem.image = UIImage(systemName: $0
                        ? "line.horizontal.3.decrease.circle.fill"
                        : "line.horizontal.3.decrease.circle")
                }
                .store(in: &cancellables)
        }

        viewModel.state.isLoading
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.activityView.stopAnimating()
                    self?.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.state.items
            .map { !$0.isEmpty }
            .assign(to: \.isEnabled, on: selectBarButtonItem)
            .store(in: &cancellables)

        let items = viewModel.state.items
        let hasItems = viewModel.state.isLoading
            .first(where: { $0 == false })
            .flatMap { _ in items }
            .map { !$0.isEmpty }

        hasItems
            .assign(to: \.isHidden, on: emptyStateView)
            .store(in: &cancellables)

        hasItems
            .map { $0 ? UITableViewCell.SeparatorStyle.singleLine : UITableViewCell.SeparatorStyle.none }
            .assign(to: \.separatorStyle, on: tableView)
            .store(in: &cancellables)

        viewModel.state.items
            .sink { [weak self] items in
                self?.update(with: items)
            }
            .store(in: &cancellables)

        for button in [pauseBarButtonItem, resumeBarButtonItem, removeBarButtonItem, moreBarButtonItem] {
            viewModel.state.editActionsEnabled
                .assign(to: \.isEnabled, on: button)
                .store(in: &cancellables)
        }
    }

    private func configureTableView() {
        tableView.rowHeight = TorrentTableViewCell.estimatedHeight
        tableView.estimatedRowHeight = TorrentTableViewCell.estimatedHeight
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.separatorStyle = .none
        tableView.register(TorrentTableViewCell.self, forCellReuseIdentifier: "torrent")

        dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "torrent",
                for: indexPath
            ) as? TorrentTableViewCell else {
                return nil
            }

            cell.configure(with: item)
            return cell
        }

        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
    }

    private func update(with items: [TorrentListItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, TorrentListItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)

        if applySnapshotInBackground {
            DispatchQueue.global(qos: .userInteractive).async {
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        } else {
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let center = CGPoint(
            x: tableView.bounds.width * 0.5,
            y: tableView.bounds.height * 0.5 - tableView.adjustedContentInset.top
        )
        activityView.sizeToFit()
        activityView.center = center
        emptyStateView.sizeToFit()
        emptyStateView.center = center
    }

    // MARK: Editing

    private func configureNormalBarButtonItems() {
        navigationItem.leftBarButtonItem = settingsBarButtonItem
        navigationItem.rightBarButtonItem = selectBarButtonItem
    }

    private func configureEditingBarButtonItems() {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }

    private func configureNormalToolbarItems() {
        var toolbarItems = [UIBarButtonItem]()

        if viewModel.state.showFilterButton {
            toolbarItems.append(filterBarButtonItem)
        }

        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        toolbarItems.append(UIBarButtonItem(customView: statusView))
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        if viewModel.state.showAddButton {
            toolbarItems.append(addBarButtonItem)
        }

        self.toolbarItems = toolbarItems
    }

    private func configureEditingToolbarItems() {
        toolbarItems = [
            resumeBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            pauseBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            removeBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            moreBarButtonItem,
        ]
    }

    // MARK: Actions

    @objc
    private func settingsButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.settingsSelected)
    }

    @objc
    private func filterButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.filterSelected(source: .barButton(sender)))
    }

    @objc
    private func addButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.addSelected(source: .barButton(sender)))
    }

    @objc
    private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.handle(.refresh)
    }

    @objc
    private func selectButtonTapped(_ sender: UIBarButtonItem) {
        setEditing(true, animated: true)
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        viewModel.handle(.didBeginEditing)
        configureEditingBarButtonItems()
        configureEditingToolbarItems()
    }

    @objc
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        setEditing(false, animated: true)
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        viewModel.handle(.didEndEditing)
        viewModel.handle(.multiSelectUpdated(indices: []))
        configureNormalBarButtonItems()
        configureNormalToolbarItems()
    }

    @objc
    private func resumeButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.resumeSelected(indices: indices))
    }

    @objc
    private func pauseButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.pauseSelected(indices: indices))
    }

    @objc
    private func removeButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.removeSelected(indices: indices, source: .barButton(sender)))
    }

    @objc
    private func moreButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.moreOptionsSelected(indices: indices, source: .barButton(sender)))
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isEditing else {
            viewModel.handle(.multiSelectUpdated(indices: tableView.indexPathsForSelectedRows?.map(\.row) ?? []))
            return
        }

        viewModel.handle(.itemSelected(index: indexPath.row))
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            viewModel.handle(.multiSelectUpdated(indices: tableView.indexPathsForSelectedRows?.map(\.row) ?? []))
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: { [weak self] in
                self?.provider?.previewForItem(at: indexPath.row)
            },
            actionProvider: { [weak self] _ in
                self?.provider?.contextMenuForItem(at: indexPath.row)
            }
        )
    }

    override func tableView(
        _ tableView: UITableView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        guard let indexPath = configuration.identifier as? IndexPath else { return }
        animator.addAnimations {
            self.provider?.commitPreviewForItem(at: indexPath.row)
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }

    override func tableView(
        _ tableView: UITableView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        provider?.didDismissPreviewForItem(at: indexPath.row)
        return nil
    }

    override func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        return provider?.leadingSwipeActionsConfigurationForItem(
            at: indexPath.row,
            source: .view(cell, rect: cell.bounds)
        )
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        return provider?.trailingSwipeActionsConfigurationForItem(
            at: indexPath.row,
            source: .view(cell, rect: cell.bounds)
        )
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.handle(.search(query: searchController.searchBar.text))
    }
}
