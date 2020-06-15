import Combine
import CommonModels
import Coordinator
import UIKit
import ViewModel

protocol TorrentListViewDelegate: AnyObject {
    func previewForItem(at index: Int) -> UIViewController?
    func commitPreviewForItem(at index: Int)
    func didDismissPreviewForItem(at index: Int)
}

// swiftlint:disable:next line_length
final class TorrentListViewController<VM: ViewModel>: PresentableTableViewController, UISearchResultsUpdating where VM.ViewEvent == TorrentListViewEvent, VM.ViewValues == TorrentListViewValues {
    private enum Section {
        case main
    }

    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: DataSource!
    weak var delegate: TorrentListViewDelegate?

    private lazy var settingsBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "gear"),
        style: .plain,
        target: self,
        action: #selector(settingsButtonTapped(_:))
    )

    private lazy var selectBarButtonItem = UIBarButtonItem(
        title: "Select",
        style: .plain,
        target: self,
        action: #selector(selectButtonTapped(_:))
    )

    private lazy var doneBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(doneButtonTapped(_:))
    )

    private lazy var addBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "plus"),
        style: .plain,
        target: self,
        action: #selector(addButtonTapped(_:))
    )

    private lazy var filterBarButtonItem = UIBarButtonItem(
        image: nil,
        style: .plain,
        target: self,
        action: #selector(filterButtonTapped(_:))
    )

    private lazy var resumeBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "play.circle"),
        style: .plain,
        target: self,
        action: #selector(resumeButtonTapped(_:))
    )

    private lazy var pauseBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "pause.circle"),
        style: .plain,
        target: self,
        action: #selector(pauseButtonTapped(_:))
    )

    private lazy var removeBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "trash.circle"),
        style: .plain,
        target: self,
        action: #selector(removeButtonTapped(_:))
    )

    private lazy var moreBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "ellipsis.circle"),
        style: .plain,
        target: self,
        action: #selector(moreButtonTapped(_:))
    )

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
        label.font = .init(descriptor: descriptor, size: 0)
        label.text = "No Torrents"
        label.textColor = .placeholderText
        return label
    }()

    private lazy var statusView: ToolbarInfoView = {
        let view = ToolbarInfoView()
        view.configure(content: viewModel.values.status)
        return view
    }()

    // MARK: Initialization

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .plain)
        viewModel.values.title.sink { [weak self] in self?.title = $0 }.store(in: &cancellables)
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

        refreshControl = .init()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        if viewModel.values.showFilterButton {
            viewModel.values.hasActiveFilters.sink { [weak self] in
                self?.filterBarButtonItem.image = UIImage(systemName: $0
                    ? "line.horizontal.3.decrease.circle.fill"
                    : "line.horizontal.3.decrease.circle")
            }.store(in: &cancellables)
        }

        viewModel.values.isLoading.sink { [weak self] isLoading in
            if !isLoading {
                self?.activityView.stopAnimating()
                self?.refreshControl?.endRefreshing()
            }
        }.store(in: &cancellables)

        viewModel.values.isEditing.sink { [weak self] isEditing in
            if isEditing {
                self?.configureEditingState()
            } else {
                self?.configureNormalState()
            }
        }.store(in: &cancellables)

        viewModel.values.items
            .map { !$0.isEmpty }
            .assign(to: \.isEnabled, on: selectBarButtonItem)
            .store(in: &cancellables)

        let items = viewModel.values.items
        let hasItems = viewModel.values.isLoading
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

        viewModel.values.items.sink { [weak self] items in
            self?.update(with: items)
        }.store(in: &cancellables)

        for button in [pauseBarButtonItem, resumeBarButtonItem, removeBarButtonItem, moreBarButtonItem] {
            viewModel.values.editActionsEnabled
                .assign(to: \.isEnabled, on: button)
                .store(in: &cancellables)
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

    private func configureTableView() {
        tableView.rowHeight = TorrentTableViewCell.estimatedHeight
        tableView.estimatedRowHeight = TorrentTableViewCell.estimatedHeight
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.separatorStyle = .none
        tableView.register(TorrentTableViewCell.self, forCellReuseIdentifier: "torrent")

        dataSource = .init(tableView: tableView) { tableView, indexPath, item in
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

    // MARK: Methods

    private func update(with items: [TorrentListItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, TorrentListItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)

        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

    // MARK: Editing

    private func configureNormalState() {
        setEditing(false, animated: true)
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        viewModel.send(.multiSelectUpdated(indices: []))
        configureNormalBarButtonItems()
        configureNormalToolbarItems()
    }

    private func configureEditingState() {
        tableView.setEditing(false, animated: true) // required to close swipe actions
        setEditing(true, animated: true)
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        configureEditingBarButtonItems()
        configureEditingToolbarItems()
    }

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

        if viewModel.values.showFilterButton {
            toolbarItems.append(filterBarButtonItem)
        }

        toolbarItems.append(.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        toolbarItems.append(.init(customView: statusView))
        toolbarItems.append(.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        if viewModel.values.showAddButton {
            toolbarItems.append(addBarButtonItem)
        }

        self.toolbarItems = toolbarItems
    }

    private func configureEditingToolbarItems() {
        toolbarItems = [
            resumeBarButtonItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            pauseBarButtonItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            removeBarButtonItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            moreBarButtonItem,
        ]
    }

    // MARK: Actions

    @objc
    private func settingsButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.settingsSelected)
    }

    @objc
    private func filterButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.filterSelected(source: .barButton(sender)))
    }

    @objc
    private func addButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.addSelected(source: .barButton(sender)))
    }

    @objc
    private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.send(.refresh)
    }

    @objc
    private func selectButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.editSelected)
    }

    @objc
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.doneEditingSelected)
    }

    @objc
    private func resumeButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.send(.resumeSelected(indices: indices))
    }

    @objc
    private func pauseButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.send(.pauseSelected(indices: indices))
    }

    @objc
    private func removeButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.send(.removeSelected(indices: indices, source: .barButton(sender)))
    }

    @objc
    private func moreButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.send(.moreOptionsSelected(indices: indices, source: .barButton(sender)))
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isEditing else {
            viewModel.send(.multiSelectUpdated(indices: tableView.indexPathsForSelectedRows?.map(\.row) ?? []))
            return
        }

        viewModel.send(.itemSelected(index: indexPath.row))
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            viewModel.send(.multiSelectUpdated(indices: tableView.indexPathsForSelectedRows?.map(\.row) ?? []))
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        .init(
            identifier: indexPath as NSCopying,
            previewProvider: { [weak self] in
                self?.delegate?.previewForItem(at: indexPath.row)
            },
            actionProvider: { [weak self] _ in
                self?.viewModel.values.contextMenu(indexPath.row)?.createUIMenu()
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
            self.delegate?.commitPreviewForItem(at: indexPath.row)
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }

    override func tableView(
        _ tableView: UITableView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        delegate?.didDismissPreviewForItem(at: indexPath.row)
        return nil
    }

    override func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        return viewModel.values.leadingSwipeActionsConfiguration(
            indexPath.row,
            PopoverSource.view(cell, rect: cell.bounds)
        )?.createUISwipeActionsConfiguration()
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        return viewModel.values.trailingSwipeActionsConfiguration(
            indexPath.row,
            PopoverSource.view(cell, rect: cell.bounds)
        )?.createUISwipeActionsConfiguration()
    }

    override func tableView(
        _ tableView: UITableView,
        shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
    ) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        viewModel.send(.editSelected)
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.send(.search(query: searchController.searchBar.text))
    }
}

private extension TorrentListViewController {
    private class DataSource: UITableViewDiffableDataSource<Section, TorrentListItem> {
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            true
        }
    }
}
