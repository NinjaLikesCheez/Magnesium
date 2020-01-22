//
//  TorrentListViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class TorrentListViewController: UITableViewController {
    private enum Section {
        case main
    }

    private let viewModel: TorrentListViewModel
    private var observers = [AnyCancellable]()
    private var refreshObserver: AnyCancellable?
    private var dataSource: UITableViewDiffableDataSource<Section, AnyTorrentListItemViewModel>!
    fileprivate var applySnapshotInBackground = true

    init(viewModel: TorrentListViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
        title = "Torrents"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped(_:))
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped(_:))
        )
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

            cell.configure(with: item)
            return cell
        }

        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource

        viewModel.items
            .sink { [weak self] items in
                self?.update(with: items)
            }
            .store(in: &observers)
    }

    private func update(with items: [AnyTorrentListItemViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, AnyTorrentListItemViewModel>()
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

    @objc
    private func settingsButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.didSelectSettings()
    }

    @objc
    private func addButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.didSelectAdd()
    }

    @objc
    private func refreshControlTriggered(_ sender: UIRefreshControl) {
        refreshObserver = viewModel.refresh().sink(receiveCompletion: { [weak sender] _ in
            sender?.endRefreshing()
        }, receiveValue: { _ in })
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath.row)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

#if DEBUG
    struct TorrentListViewController_Previews: PreviewProvider {
        private struct Container: UIViewControllerRepresentable {
            let viewModel: TorrentListViewModel

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container>
            ) -> TorrentListViewController {
                let viewController = TorrentListViewController(viewModel: viewModel)
                viewController.applySnapshotInBackground = false
                return viewController
            }

            func updateUIViewController(
                _ uiViewController: TorrentListViewController,
                context: UIViewControllerRepresentableContext<Container>
            ) {}
        }

        private final class Coordinator: PreviewCoordinator, TorrentListCoordinator {
            func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {}
            func showSettings() {}
            func showAddLink() -> AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }
        }

        static var previews: some View {
            let viewModel = EmptyTorrentListViewModel(coordinator: Coordinator())
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
