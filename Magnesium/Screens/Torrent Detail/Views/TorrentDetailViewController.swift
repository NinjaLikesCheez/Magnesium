import Combine
import Coordinator
import UIKit
import ViewModel

protocol TorrentDetailViewControllerIdentifiable {
    var torrentHash: String { get }
}

// swiftlint:disable:next line_length
final class TorrentDetailViewController<VM: ViewModel>: PresentableTableViewController, TorrentDetailViewControllerIdentifiable where VM.ViewEvent == TorrentDetailViewEvent, VM.ViewRepresentation == TorrentDetailViewRepresentation {
    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UITableViewDiffableDataSource<TorrentDetailSectionType, TorrentDetailItem>!
    private var isFirstSnapshot = true
    private var expandedInfoIDs = Set<TorrentDetailInfoItem.ID>()

    var torrentHash: String {
        viewModel.view.hash
    }

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = L10n.torrentInfoScreenTitle
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = [
            .init(
                image: UIImage(systemName: "ellipsis.circle"),
                style: .plain,
                target: self,
                action: #selector(moreButtonTapped(_:))
            ),
        ]
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

        viewModel.view.isRefreshing
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.view.sections
            .sink { [weak self] sections in
                self?.update(with: sections)
            }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.receive(.appear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.receive(.disappear)
    }

    private func configureTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorStyle = .none
        tableView.contentInset.top = 20
        tableView.register(TorrentDetailHeaderTableViewCell.self, forCellReuseIdentifier: "header")
        tableView.register(TorrentDetailInfoTableViewCell.self, forCellReuseIdentifier: "info")
        tableView.register(TorrentDetailTrackerTableViewCell.self, forCellReuseIdentifier: "tracker")
        tableView.register(TorrentDetailFileTableViewCell.self, forCellReuseIdentifier: "file")
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
        viewModel.receive(.refresh)
    }

    @objc
    private func moreButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.receive(.moreOptions(source: .barButton(sender)))
    }

    // MARK: UITableViewDelegate

    private func titleForSection(_ type: TorrentDetailSectionType) -> String? {
        switch type {
        case .header:
            return nil
        case .info:
            return L10n.torrentInfoSectionInfo
        case .trackers:
            return L10n.torrentInfoSectionTrackers
        case .files:
            return L10n.torrentInfoSectionFiles
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        guard titleForSection(section) != nil else { return .leastNormalMagnitude }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        guard let title = titleForSection(section) else { return nil }
        let header = TorrentDetailSectionHeaderView()
        header.configure(title: title)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        .init()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
}

extension TorrentDetailViewController: TorrentDetailHeaderTableViewCellDelegate {
    func headerDidSelectPause(_ header: TorrentDetailHeaderTableViewCell) {
        viewModel.receive(.pause)
    }

    func headerDidSelectResume(_ header: TorrentDetailHeaderTableViewCell) {
        viewModel.receive(.resume)
    }

    func headerDidSelectRemove(_ header: TorrentDetailHeaderTableViewCell, sender: UIView) {
        viewModel.receive(.remove(source: .view(sender, rect: sender.bounds)))
    }

    func headerDidResize(_ header: TorrentDetailHeaderTableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
