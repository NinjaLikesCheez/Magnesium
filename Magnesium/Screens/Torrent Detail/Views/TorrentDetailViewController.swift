//
//  TorrentDetailViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

final class TorrentDetailViewController: UITableViewController {
    private let viewModel: TorrentDetailViewModel
    private var observers = [AnyCancellable]()
    private var refreshObserver: AnyCancellable?
    private var dataSource: UITableViewDiffableDataSource<TorrentDetailSection, TorrentDetailItem>!
    private var isFirstSnapshot = true

    init(viewModel: TorrentDetailViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
        title = "Info"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "ellipsis.circle"),
                style: .plain,
                target: nil,
                action: nil
            ),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        tableView.backgroundColor = .systemBackground
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(TorrentDetailHeaderTableViewCell.self, forCellReuseIdentifier: "header")
        tableView.register(TorrentDetailInfoTableViewCell.self, forCellReuseIdentifier: "info")
        tableView.register(TorrentDetailTrackerTableViewCell.self, forCellReuseIdentifier: "tracker")
        tableView.register(TorrentDetailFileTableViewCell.self, forCellReuseIdentifier: "file")
        tableView.tableHeaderView = {
            var frame = CGRect.zero
            frame.size.height = .leastNormalMagnitude
            return UIView(frame: frame)
        }()
        tableView.tableFooterView = UIView()

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case let .header(viewModel):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "header",
                    for: indexPath
                ) as? TorrentDetailHeaderTableViewCell else {
                    return nil
                }

                cell.configure(with: viewModel)
                return cell
            case let .info(viewModel):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "info",
                    for: indexPath
                ) as? TorrentDetailInfoTableViewCell else {
                    return nil
                }

                cell.configure(
                    with: viewModel,
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
                    withTracker: tracker,
                    isLastRow: indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
                )
                return cell
            case let .file(viewModel):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "file",
                    for: indexPath
                ) as? TorrentDetailFileTableViewCell else {
                    return nil
                }

                cell.configure(
                    with: viewModel,
                    isLastRow: indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
                )
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.sections
            .sink { [weak self] items in
                self?.update(with: items)
            }
            .store(in: &observers)
    }

    private func update(with sections: [(TorrentDetailSection, [TorrentDetailItem])]) {
        let animate = !isFirstSnapshot
        isFirstSnapshot = false

        var snapshot = NSDiffableDataSourceSnapshot<TorrentDetailSection, TorrentDetailItem>()

        for (section, items) in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        }

        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }

    @objc
    private func refreshControlTriggered(_ sender: Any) {
        refreshObserver = viewModel.refresh().sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                break
            case let .failure(error):
                // TODO: display error
                debugPrint(error)
            }

            self?.refreshControl?.endRefreshing()
        }, receiveValue: {})
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        guard section.displayString != nil else { return .leastNormalMagnitude }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        guard let title = section.displayString else { return nil }
        let header = TorrentDetailSectionHeaderView()
        header.configure(withTitle: title)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        switch section {
        case .header:
            return .leastNormalMagnitude
        case .info, .trackers, .files:
            return 20
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
