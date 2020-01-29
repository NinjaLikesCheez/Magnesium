//
//  TorrentDetailViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

protocol TorrentDetailViewControllerIdentifiable {}

final class TorrentDetailViewController<VM: ViewModel>: UITableViewController, TorrentDetailViewControllerIdentifiable
    where VM.ViewEvent == TorrentDetailViewEvent, VM.ViewState == TorrentDetailViewState {
    private let viewModel: VM
    private var observers = [AnyCancellable]()
    private var refreshObserver: AnyCancellable?
    private var dataSource: UITableViewDiffableDataSource<TorrentDetailSectionType, TorrentDetailItem>!
    private var isFirstSnapshot = true

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)

        title = "Info"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "ellipsis.circle"),
                style: .plain,
                target: self,
                action: #selector(moreButtonTapped(_:))
            ),
        ]

        viewModel.state.isLoading
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.refreshControl?.beginRefreshing()
                } else {
                    self?.refreshControl?.endRefreshing()
                }
            }
            .store(in: &observers)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.contentInset.top = 20
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

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            switch item {
            case let .header(viewModel):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "header",
                    for: indexPath
                ) as? TorrentDetailHeaderTableViewCell else {
                    return nil
                }

                cell.delegate = self
                cell.configure(with: viewModel.state)
                return cell
            case let .info(name, value):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "info",
                    for: indexPath
                ) as? TorrentDetailInfoTableViewCell else {
                    return nil
                }

                cell.configure(
                    name: name,
                    value: value,
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
                    with: viewModel.state,
                    isLastRow: indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1
                )
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.state.sections
            .sink { [weak self] sections in
                self?.update(with: sections)
            }
            .store(in: &observers)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.handle(.appear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.handle(.disappear)
    }

    private func update(with sections: [TorrentDetailSection]) {
        let animate = !isFirstSnapshot
        isFirstSnapshot = false

        var snapshot = NSDiffableDataSourceSnapshot<TorrentDetailSectionType, TorrentDetailItem>()

        for section in sections {
            snapshot.appendSections([section.type])
            snapshot.appendItems(section.items, toSection: section.type)
        }

        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }

    @objc
    private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.handle(.refresh)
    }

    @objc
    private func moreButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.moreOptions(source: .barButton(sender)))
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        guard section.displayString != nil else { return .leastNormalMagnitude }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        guard let title = section.displayString else { return nil }
        let header = TorrentDetailSectionHeaderView()
        header.configure(title: title)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension TorrentDetailViewController: TorrentDetailHeaderTableViewCellDelegate {
    func headerDidSelectPause(_ header: TorrentDetailHeaderTableViewCell) {
        viewModel.handle(.pause)
    }

    func headerDidSelectResume(_ header: TorrentDetailHeaderTableViewCell) {
        viewModel.handle(.resume)
    }

    func headerDidSelectRemove(_ header: TorrentDetailHeaderTableViewCell, sender: UIView) {
        viewModel.handle(.remove(source: .view(sender, rect: sender.bounds)))
    }
}
