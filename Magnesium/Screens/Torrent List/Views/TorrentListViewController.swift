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

    private struct Item: Equatable, Hashable {
        let viewModel: AnyTorrentListItemViewModel

        static func == (lhs: Item, rhs: Item) -> Bool {
            return type(of: lhs.viewModel.base) == type(of: rhs.viewModel.base) && lhs.viewModel.id == rhs.viewModel.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(viewModel.id)
        }
    }

    private class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
    }

    private let viewModel: VM
    private var observers = [AnyCancellable]()
    private var dataSource: DataSource!
    private var filterBarButtonItem: UIBarButtonItem?
    fileprivate var applySnapshotInBackground = true
    weak var provider: TorrentListViewProvider?

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .plain)
        title = NSLocalizedString("torrents_screen_title", comment: "Torrents")
        configureNavigationItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        if viewModel.state.showFilterButton {
            viewModel.state.hasActiveFilters
                .sink { [weak self] in
                    self?.filterBarButtonItem?.image = UIImage(systemName: $0
                        ? "line.horizontal.3.decrease.circle.fill"
                        : "line.horizontal.3.decrease.circle")
                }
                .store(in: &observers)
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

        viewModel.state.items
            .sink { [weak self] items in
                self?.update(with: items)
            }
            .store(in: &observers)
    }

    private func configureNavigationItem() {
        navigationItem.searchController = searchController
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
            let item = UIBarButtonItem(
                image: nil,
                style: .plain,
                target: self,
                action: #selector(filterButtonTapped(_:))
            )
            filterBarButtonItem = item
            rightButtons.append(item)
        }

        navigationItem.rightBarButtonItems = rightButtons
    }

    private func configureTableView() {
        tableView.rowHeight = TorrentTableViewCell.estimatedHeight
        tableView.estimatedRowHeight = TorrentTableViewCell.estimatedHeight
        tableView.register(TorrentTableViewCell.self, forCellReuseIdentifier: "torrent")

        dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
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
