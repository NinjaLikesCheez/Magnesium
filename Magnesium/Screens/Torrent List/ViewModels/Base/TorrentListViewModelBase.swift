//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import LinkPresentation
import UIKit
import ViewModel

final class AnyTorrentListViewModel: ViewModel, EventEmitter, TorrentListProvider {
    private let _events: () -> AnyPublisher<Event, Never>
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void
    private let _viewModelForItem: (Int) -> AnyTorrentDetailViewModel?
    private let _contextMenuForItem: (Int) -> UIMenu?
    private let _leadingSwipeActionsConfigurationForItem: (Int, PopoverSource) -> UISwipeActionsConfiguration?
    private let _trailingSwipeActionsConfigurationForItem: (Int, PopoverSource) -> UISwipeActionsConfiguration?
    let base: Any

    var state: TorrentListViewState { _state() }
    var events: AnyPublisher<TorrentListEvent, Never> { _events() }

    init<Base>(_ base: Base) where
        Base: ViewModel,
        Base: EventEmitter,
        Base: TorrentListProvider,
        Base.Event == Event,
        Base.ViewEvent == ViewEvent,
        Base.ViewState == ViewState {
        self.base = base
        _events = { base.events }
        _state = { base.state }
        _handle = { base.handle($0) }
        _viewModelForItem = { base.detailViewModelForItem(at: $0) }
        _contextMenuForItem = { base.contextMenuForItem(at: $0) }
        _leadingSwipeActionsConfigurationForItem = { base.leadingSwipeActionsConfigurationForItem(at: $0, source: $1) }
        _trailingSwipeActionsConfigurationForItem = {
            base.trailingSwipeActionsConfigurationForItem(at: $0, source: $1)
        }
    }

    func handle(_ event: TorrentListViewEvent) {
        _handle(event)
    }

    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        return _viewModelForItem(index)
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        return _contextMenuForItem(index)
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration? {
        return _leadingSwipeActionsConfigurationForItem(index, source)
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> UISwipeActionsConfiguration? {
        return _trailingSwipeActionsConfigurationForItem(index, source)
    }
}

protocol TorrentListProvider: AnyObject {
    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel?
    func contextMenuForItem(at index: Int) -> UIMenu?
    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration?
    func trailingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration?
}

enum TorrentListEvent {
    case alert(Alert, source: PopoverSource?)
    case activities([UIActivity], metadata: LPLinkMetadata)
    case add(source: PopoverSource, linkSubject: PassthroughSubject<String, Never>)
    case filter(source: PopoverSource, labels: CurrentValueSubject<[StandardLabel], Never>)
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
}

enum TorrentListViewEvent {
    case refresh
    case addSelected(source: PopoverSource)
    case filterSelected(source: PopoverSource)
    case itemSelected(index: Int)
    case settingsSelected
    case search(query: String?)
}

struct TorrentListViewState {
    var showAddButton: Bool = true
    var showFilterButton: Bool = true
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    var isLoading: AnyPublisher<Bool, Never>
    var hasActiveFilters: AnyPublisher<Bool, Never>
}
