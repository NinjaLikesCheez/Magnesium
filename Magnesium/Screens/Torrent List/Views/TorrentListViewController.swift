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
    fileprivate var applySnapshotInBackground = true
    weak var provider: TorrentListViewProvider?

    private lazy var settingsBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped(_:))
        )
    }()

    private lazy var selectBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            title: "Select",
            style: .plain,
            target: self,
            action: #selector(selectButtonTapped(_:))
        )
    }()

    private lazy var doneBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(_:)))
    }()

    private lazy var addBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped(_:))
        )
    }()

    private lazy var filterBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: nil,
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped(_:))
        )
    }()

    private lazy var resumeBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "play.circle"),
            style: .plain,
            target: self,
            action: #selector(resumeButtonTapped(_:))
        )
    }()

    private lazy var pauseBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "pause.circle"),
            style: .plain,
            target: self,
            action: #selector(pauseButtonTapped(_:))
        )
    }()

    private lazy var removeBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "trash.circle"),
            style: .plain,
            target: self,
            action: #selector(removeButtonTapped(_:))
        )
    }()

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped(_:))
        )
    }()

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

    // MARK: Initialization

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .plain)
        viewModel.state.title.sink { [weak self] in self?.title = $0 }.store(in: &observers)
        navigationItem.searchController = searchController
        configureNormalBarButtonItems()
        configureNormalToolbarItems()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()

        activityView.startAnimating()
        tableView.addSubview(activityView)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        if viewModel.state.showFilterButton {
            viewModel.state.hasActiveFilters
                .sink { [weak self] in
                    self?.filterBarButtonItem.image = UIImage(systemName: $0
                        ? "line.horizontal.3.decrease.circle.fill"
                        : "line.horizontal.3.decrease.circle")
                }
                .store(in: &observers)
        }

        viewModel.state.isLoading
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.activityView.stopAnimating()
                    self?.refreshControl?.endRefreshing()
                }
            }
            .store(in: &observers)

        viewModel.state.items
            .map { !$0.isEmpty }
            .assign(to: \.isEnabled, on: selectBarButtonItem)
            .store(in: &observers)

        viewModel.state.items
            .sink { [weak self] items in
                self?.update(with: items)
            }
            .store(in: &observers)

        for button in [pauseBarButtonItem, resumeBarButtonItem, removeBarButtonItem, moreBarButtonItem] {
            viewModel.state.editActionsEnabled
                .assign(to: \.isEnabled, on: button)
                .store(in: &observers)
        }
    }

    private func configureTableView() {
        tableView.rowHeight = TorrentTableViewCell.estimatedHeight
        tableView.estimatedRowHeight = TorrentTableViewCell.estimatedHeight
        tableView.allowsMultipleSelectionDuringEditing = true
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityView.sizeToFit()
        activityView.center = CGPoint(
            x: tableView.bounds.width * 0.5,
            y: tableView.bounds.height * 0.5 - tableView.adjustedContentInset.top
        )
    }

    // MARK: Editing

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

        if viewModel.state.showFilterButton {
            toolbarItems.append(filterBarButtonItem)
        }

        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        if viewModel.state.showAddButton {
            toolbarItems.append(addBarButtonItem)
        }

        self.toolbarItems = toolbarItems
    }

    private func configureEditingToolbarItems() {
        toolbarItems = [
            resumeBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            pauseBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            removeBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            moreBarButtonItem,
        ]
    }

    // MARK: Actions

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

    @objc
    private func selectButtonTapped(_ sender: UIBarButtonItem) {
        setEditing(true, animated: true)
        viewModel.handle(.didBeginEditing)
        configureEditingBarButtonItems()
        configureEditingToolbarItems()
    }

    @objc
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        setEditing(false, animated: true)
        viewModel.handle(.didEndEditing)
        viewModel.handle(.multiSelectUpdated(indices: []))
        configureNormalBarButtonItems()
        configureNormalToolbarItems()
    }

    @objc
    private func resumeButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.resumeSelected(indices: indices))
    }

    @objc
    private func pauseButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.pauseSelected(indices: indices))
    }

    @objc
    private func removeButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.removeSelected(indices: indices, source: .barButton(sender)))
    }

    @objc
    private func moreButtonTapped(_ sender: UIBarButtonItem) {
        guard let indices = tableView.indexPathsForSelectedRows?.map({ $0.row }) else { return }
        viewModel.handle(.moreOptionsSelected(indices: indices, source: .barButton(sender)))
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isEditing else {
            viewModel.handle(.multiSelectUpdated(indices: tableView.indexPathsForSelectedRows?.map(\.row) ?? []))
            return
        }

        viewModel.handle(.itemSelected(index: indexPath.row))
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            viewModel.handle(.multiSelectUpdated(indices: tableView.indexPathsForSelectedRows?.map(\.row) ?? []))
        }
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
