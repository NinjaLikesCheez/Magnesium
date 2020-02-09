//
//  TorrentListViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import UIKit
import ViewModel

/// A type that is able to provide previews for a `TorrentListViewController`.
protocol TorrentListViewPreviewProvider: AnyObject {
    /// The user has requested a preview for the item at the provided index.
    /// - Parameter index: The item index to create a preview for.
    func previewForItem(at index: Int) -> UIViewController?
    /// The user has requested a preview for the item at the provided index.
    /// - Parameter index: The item index to return actions for.
    func contextMenuForItem(at index: Int) -> UIMenu?
    /// The user has selected the preview indicating that it should be committed.
    /// - Parameter index: The item index whose preview is being committed.
    func commitPreviewForItem(at index: Int)
    /// Called when a preview is dismissed. Use this opportunity to release any cached state related to the preview.
    func didDismissPreviewForItem(at index: Int)
}

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
    private var dataSource: UITableViewDiffableDataSource<Section, Item>!
    fileprivate var applySnapshotInBackground = true
    weak var previewProvider: TorrentListViewPreviewProvider?

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

        var rightButtons = [UIBarButtonItem]()
        if viewModel.state.showAddButton {
            rightButtons.append(UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                style: .plain,
                target: self,
                action: #selector(addButtonTapped(_:))
            ))
        }

        if viewModel.state.showFilterButton {
            let filterItem = UIBarButtonItem(
                image: nil,
                style: .plain,
                target: self,
                action: #selector(filterButtonTapped(_:))
            )
            viewModel.state.hasActiveFilters
                .sink { [weak filterItem] in
                    filterItem?.image = UIImage(systemName: $0
                        ? "line.horizontal.3.decrease.circle.fill"
                        : "line.horizontal.3.decrease.circle")
                }
                .store(in: &observers)
            rightButtons.append(filterItem)
        }

        navigationItem.rightBarButtonItems = rightButtons

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

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.handle(.itemSelected(index: indexPath.row))
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
                self?.previewProvider?.previewForItem(at: indexPath.row)
            },
            actionProvider: { [weak self] _ in
                self?.previewProvider?.contextMenuForItem(at: indexPath.row)
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
            self.previewProvider?.commitPreviewForItem(at: indexPath.row)
        }
    }

    override func tableView(
        _ tableView: UITableView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        previewProvider?.didDismissPreviewForItem(at: indexPath.row)
        return nil
    }
}
