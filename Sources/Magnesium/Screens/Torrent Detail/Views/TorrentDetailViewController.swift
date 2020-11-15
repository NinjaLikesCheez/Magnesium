import Combine
import Coordinator
import UIKit
import ViewModel

protocol TorrentDetailViewControllerIdentifiable {
    var torrentHash: String { get }
}

final class TorrentDetailViewController<VM: ViewModel>: PresentableTableViewController,
    TorrentDetailViewControllerIdentifiable
    where VM.ViewEvent == TorrentDetailViewEvent, VM.ViewValues == TorrentDetailViewValues
{ // swiftlint:disable:this opening_brace
    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: DataSource!
    private var isFirstSnapshot = true
    private var expandedInfoIDs = Set<String>()

    private lazy var doneBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(doneButtonTapped(_:))
    )

    private lazy var moreBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "ellipsis.circle"),
        style: .plain,
        target: self,
        action: #selector(moreButtonTapped(_:))
    )

    private lazy var filePriorityBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.up.arrow.down.circle"),
        style: .plain,
        target: self,
        action: #selector(filePriorityButtonTapped(_:))
    )

    private lazy var selectAllBarButtonItem = UIBarButtonItem(
        title: L10n.Action.selectAll,
        style: .plain,
        target: self,
        action: #selector(selectAllButtonTapped(_:))
    )

    private lazy var toolbarInfoView = ToolbarInfoView()

    var torrentHash: String {
        viewModel.values.hash
    }

    // MARK: Initialization

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = L10n.Screen.TorrentInfo.title
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = moreBarButtonItem
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureDataSource()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.send(.appeared)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.send(.disappeared)
    }

    // MARK: Configuration

    private func configureView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorStyle = .none
        tableView.contentInset.top = 20
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.tableHeaderView = {
            var frame = CGRect.zero
            frame.size.height = .leastNormalMagnitude
            return .init(frame: frame)
        }()
        tableView.tableFooterView = .init()
    }

    private func configureDataSource() {
        tableView.register(TorrentDetailHeaderTableViewCell.self, forCellReuseIdentifier: "header")
        tableView.register(TorrentDetailInfoTableViewCell.self, forCellReuseIdentifier: "info")
        tableView.register(TorrentDetailTrackerTableViewCell.self, forCellReuseIdentifier: "tracker")
        tableView.register(TorrentDetailFileTableViewCell.self, forCellReuseIdentifier: "file")
        tableView.register(TorrentDetailSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")

        dataSource = .init(tableView: tableView) { [weak self] tableView, indexPath, item in
            switch item {
            case let .header(item):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "header",
                    for: indexPath
                ) as? TorrentDetailHeaderTableViewCell else {
                    return nil
                }

                cell.delegate = self
                cell.configure(with: item)
                return cell
            case let .info(item):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "info",
                    for: indexPath
                ) as? TorrentDetailInfoTableViewCell else {
                    return nil
                }

                cell.configure(
                    with: item,
                    isExpanded: self?.expandedInfoIDs.contains(item.id) ?? false,
                    isLastRow: indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
                )
                return cell
            case let .tracker(tracker):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "tracker",
                    for: indexPath
                ) as? TorrentDetailTrackerTableViewCell else {
                    return nil
                }

                cell.configure(
                    tracker: tracker,
                    isLastRow: indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
                )
                return cell
            case let .file(item):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "file",
                    for: indexPath
                ) as? TorrentDetailFileTableViewCell else {
                    return nil
                }

                cell.configure(
                    with: item,
                    isLastRow: indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
                )
                return cell
            }
        }

        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
    }

    private func bindViewModel() {
        refreshControl = .init()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        viewModel.values.isRefreshing.sink { [weak self] isLoading in
            if !isLoading {
                self?.refreshControl?.endRefreshing()
            }
        }.store(in: &cancellables)

        viewModel.values.sections.sink { [weak self] sections in
            self?.update(with: sections)
        }.store(in: &cancellables)

        viewModel.values.editSection.sink { [weak self] section in
            if let section = section {
                self?.configureEditingState(for: section)
            } else {
                self?.configureNormalState()
            }
        }.store(in: &cancellables)

        toolbarInfoView.configure(content: viewModel.values.toolbarInfo)
    }

    private func update(with sections: [TorrentDetailSection]) {
        let animated = !isFirstSnapshot
        isFirstSnapshot = false

        var snapshot = NSDiffableDataSourceSnapshot<TorrentDetailSectionType, TorrentDetailItem>()

        for section in sections {
            snapshot.appendSections([section.type])
            snapshot.appendItems(section.items, toSection: section.type)
        }

        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }

    private func configureNormalState() {
        guard isEditing else {
            return
        }

        setEditing(false, animated: true)
        reconfigureHeaders()

        navigationController?.setToolbarHidden(true, animated: true)

        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }

        viewModel.send(.multiSelectUpdated(indexPaths: []))
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = moreBarButtonItem
    }

    private func configureEditingState(for section: TorrentDetailSectionType) {
        dataSource.editSection = section
        setEditing(true, animated: true)
        reconfigureHeaders()

        switch section {
        case .files:
            toolbarItems = [
                .init(barButtonSystemItem: .fixedSpace, target: nil, action: nil),
                .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                .init(customView: toolbarInfoView),
                .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                filePriorityBarButtonItem,
            ]
        default:
            toolbarItems = nil
        }

        navigationController?.setToolbarHidden(false, animated: true)

        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }

        navigationItem.leftBarButtonItem = selectAllBarButtonItem
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }

    private func reconfigureHeaders() {
        for section in 0 ..< dataSource.snapshot().numberOfSections {
            guard let header = tableView.headerView(forSection: section) as? TorrentDetailSectionHeaderView else {
                continue
            }

            configure(header: header, forSection: section)
        }
    }

    // MARK: Actions

    @objc
    private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.send(.refresh)
    }

    @objc
    private func moreButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.moreOptionsSelected(source: .barButton(sender)))
    }

    @objc
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.doneEditingSelected)
    }

    @objc
    private func filePriorityButtonTapped(_ sender: UIBarButtonItem) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        viewModel.send(.setFilePrioritySelected(indexPaths: indexPaths, source: .barButton(sender)))
    }

    @objc
    private func selectAllButtonTapped(_ sender: UIBarButtonItem) {
        guard let editSection = dataSource.editSection,
              let sectionIndex = dataSource.snapshot().indexOfSection(editSection)
        else {
            return
        }

        for row in 0 ..< tableView.numberOfRows(inSection: sectionIndex) {
            let indexPath = IndexPath(row: row, section: sectionIndex)
            _ = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        shouldShowHeader(forSection: section) ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard shouldShowHeader(forSection: section),
              let header = tableView.dequeueReusableHeaderFooterView(
                  withIdentifier: "header"
              ) as? TorrentDetailSectionHeaderView
        else {
            return nil
        }

        configure(header: header, forSection: section)
        return header
    }

    private func shouldShowHeader(forSection section: Int) -> Bool {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        return section != .header
    }

    private func configure(header: TorrentDetailSectionHeaderView, forSection section: Int) {
        switch dataSource.snapshot().sectionIdentifiers[section] {
        case .header:
            break
        case .info:
            header.configure(title: L10n.Screen.TorrentInfo.informationSection)
        case .trackers:
            header.configure(title: L10n.Screen.TorrentInfo.trackersSection)
        case .files:
            header.configure(
                title: L10n.Screen.TorrentInfo.filesSection,
                action: !isEditing ? L10n.Action.edit : nil,
                actionHandler: { [weak self] in
                    self?.viewModel.send(.editSectionSelected(.files))
                }
            )
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        .init()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case let .info(item) = dataSource.itemIdentifier(for: indexPath),
           !expandedInfoIDs.contains(item.id),
           item.expandedValue != nil,
           let cell = tableView.cellForRow(at: indexPath) as? TorrentDetailInfoTableViewCell
        // swiftformat:disable:next braces
        {
            expandedInfoIDs.insert(item.id)

            let isLastRow = indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
            cell.configure(with: item, isExpanded: true, isLastRow: isLastRow)
            cell.prepareForExpansion()

            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            cell.animateExpansion()
        }

        if isEditing {
            if !dataSource.tableView(tableView, canEditRowAt: indexPath) {
                tableView.deselectRow(at: indexPath, animated: true)
            }

            viewModel.send(.multiSelectUpdated(indexPaths: tableView.indexPathsForSelectedRows ?? []))
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            viewModel.send(.multiSelectUpdated(indexPaths: tableView.indexPathsForSelectedRows ?? []))
        }
    }

    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let menu = viewModel.values.contextMenu(indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil,
            actionProvider: { _ in menu.createUIMenu() }
        )
    }

    override func tableView(
        _ tableView: UITableView,
        shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
    ) -> Bool {
        dataSource.snapshot().sectionIdentifiers[indexPath.section] == .files
    }

    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        viewModel.send(.editSectionSelected(dataSource.snapshot().sectionIdentifiers[indexPath.section]))
    }
}

extension TorrentDetailViewController: TorrentDetailHeaderTableViewCellDelegate {
    func headerDidSelectPause(_ header: TorrentDetailHeaderTableViewCell) {
        viewModel.send(.pauseSelected)
    }

    func headerDidSelectResume(_ header: TorrentDetailHeaderTableViewCell) {
        viewModel.send(.resumeSelected)
    }

    func headerDidSelectRemove(_ header: TorrentDetailHeaderTableViewCell, sender: UIView) {
        viewModel.send(.removeSelected(source: .view(sender, rect: sender.bounds)))
    }

    func headerDidResize(_ header: TorrentDetailHeaderTableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

private extension TorrentDetailViewController {
    private class DataSource: UITableViewDiffableDataSource<TorrentDetailSectionType, TorrentDetailItem> {
        var editSection: TorrentDetailSectionType?

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            snapshot().sectionIdentifiers[indexPath.section] == editSection
        }
    }
}
