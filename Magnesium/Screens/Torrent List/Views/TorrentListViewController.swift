//
//  TorrentListViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import SwiftUI
import UIKit
import ViewModel

final class TorrentListViewController<VM: ViewModel>: PresentableTableViewController
    where VM.ViewEvent == TorrentListViewEvent, VM.ViewState == TorrentListViewState {
    private enum Section {
        case main
    }

    private struct Item: Equatable, Hashable {
        let viewModel: AnyTorrentListItemViewModel

        static func == (lhs: Item, rhs: Item) -> Bool {
            return type(of: lhs.viewModel.base) == type(of: rhs.viewModel.base) && lhs.viewModel.id == rhs.viewModel.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(viewModel.id)
        }
    }

    private let viewModel: VM
    private var observers = [AnyCancellable]()
    private var refreshObserver: AnyCancellable?
    private var dataSource: UITableViewDiffableDataSource<Section, Item>!
    fileprivate var applySnapshotInBackground = true

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .plain)
        title = "Torrents"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped(_:))
        )

        if viewModel.state.showAddButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                style: .plain,
                target: self,
                action: #selector(addButtonTapped(_:))
            )
        }

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

        tableView.rowHeight = TorrentTableViewCell.estimatedHeight
        tableView.estimatedRowHeight = TorrentTableViewCell.estimatedHeight
        tableView.register(TorrentTableViewCell.self, forCellReuseIdentifier: "torrent")

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "torrent",
                for: indexPath
            ) as? TorrentTableViewCell else {
                return nil
            }

            cell.configure(with: item.viewModel.state)
            return cell
        }

        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource

        viewModel.state.items
            .sink { [weak self] items in
                self?.update(with: items)
            }
            .store(in: &observers)
    }

    private func update(with viewModels: [AnyTorrentListItemViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModels.map { Item(viewModel: $0) }, toSection: .main)

        if applySnapshotInBackground {
            DispatchQueue.global(qos: .userInteractive).async {
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        } else {
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

    @objc
    private func settingsButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.settings)
    }

    @objc
    private func addButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.add(source: .barButton(sender)))
    }

    @objc
    private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.handle(.refresh)
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.handle(.selectItem(index: indexPath.row))
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

#if DEBUG
    struct TorrentListViewController_Previews: PreviewProvider {
        private struct Container<VM: ViewModel>: UIViewControllerRepresentable
            where VM.ViewEvent == TorrentListViewEvent, VM.ViewState == TorrentListViewState {
            let viewModel: VM

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container>
            ) -> TorrentListViewController<VM> {
                let viewController = TorrentListViewController(viewModel: viewModel)
                viewController.applySnapshotInBackground = false
                return viewController
            }

            func updateUIViewController(
                _ uiViewController: TorrentListViewController<VM>,
                context: UIViewControllerRepresentableContext<Container>
            ) {}
        }

        static var previews: some View {
            let viewModel = EmptyTorrentListViewModel()
            return Group {
                Container(viewModel: viewModel)
                    .previewDisplayName("Light")
                Container(viewModel: viewModel)
                    .previewDisplayName("Dark")
                    .environment(\.colorScheme, .dark)
            }
        }
    }
#endif
