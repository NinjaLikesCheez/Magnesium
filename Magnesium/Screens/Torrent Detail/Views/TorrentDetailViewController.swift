import Combine
import Coordinator
import UIKit
import ViewModel

protocol TorrentDetailViewControllerIdentifiable {
    var torrentHash: String { get }
}

// swiftlint:disable:next line_length
final class TorrentDetailViewController<VM: ViewModel>: PresentableTableViewController, TorrentDetailViewControllerIdentifiable where VM.ViewEvent == TorrentDetailViewEvent, VM.ViewValues == TorrentDetailViewValues {
    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: DataSource!
    private var isFirstSnapshot = true
    private var expandedInfoIDs = Set<TorrentDetailInfoItem.ID>()

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

    private lazy var toolbarInfoView: ToolbarInfoView = {
        let view = ToolbarInfoView()
        view.configure(content: viewModel.values.toolbarInfo)
        return view
    }()

    var torrentHash: String {
        viewModel.values.hash
    }

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = L10n.torrentInfoScreenTitle
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = moreBarButtonItem
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()

        refreshControl = .init()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        viewModel.values.isRefreshing
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.values.sections
            .sink { [weak self] sections in
                self?.update(with: sections)
            }
            .store(in: &cancellables)

        viewModel.values.editSection
            .sink { [weak self] section in
                if let section = section {
                    self?.configureEditingState(for: section)
                } else {
                    self?.configureNormalState()
                }
            }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.send(.appeared)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.send(.disappeared)
    }

    private func configureTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorStyle = .none
        tableView.contentInset.top = 20
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(TorrentDetailHeaderTableViewCell.self, forCellReuseIdentifier: "header")
        tableView.register(TorrentDetailInfoTableViewCell.self, forCellReuseIdentifier: "info")
        tableView.register(TorrentDetailTrackerTableViewCell.self, forCellReuseIdentifier: "tracker")
        tableView.register(TorrentDetailFileTableViewCell.self, forCellReuseIdentifier: "file")
        tableView.register(TorrentDetailSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.tableHeaderView = {
            var frame = CGRect.zero
            frame.size.height = .leastNormalMagnitude
            return .init(frame: frame)
        }()
        tableView.tableFooterView = .init()

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

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        shouldShowHeader(forSection: section) ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard shouldShowHeader(forSection: section),
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            as? TorrentDetailSectionHeaderView
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
            header.configure(title: L10n.torrentInfoSectionInfo)
        case .trackers:
            header.configure(title: L10n.torrentInfoSectionTrackers)
        case .files:
            header.configure(
                title: L10n.torrentInfoSectionFiles,
                action: !isEditing ? L10n.edit : nil,
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
        guard !isEditing else {
            viewModel.send(.multiSelectUpdated(indexPaths: tableView.indexPathsForSelectedRows ?? []))
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        switch dataSource.itemIdentifier(for: indexPath) {
        case let .info(item):
            guard !expandedInfoIDs.contains(item.id),
                item.expandedValue != nil,
                let cell = tableView.cellForRow(at: indexPath) as? TorrentDetailInfoTableViewCell
            else {
                return
            }

            expandedInfoIDs.insert(item.id)

            let isLastRow = indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
            cell.configure(with: item, isExpanded: true, isLastRow: isLastRow)
            cell.prepareForExpansion()

            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            cell.animateExpansion()
        default:
            break
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
        true
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
