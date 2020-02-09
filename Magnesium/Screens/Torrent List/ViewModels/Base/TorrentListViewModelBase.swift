//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit.UIMenu
import ViewModel

final class AnyTorrentListViewModel: ViewModel, EventEmitter, TorrentListPreviewProvider {
    private let _events: () -> AnyPublisher<Event, Never>
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void
    private let _viewModelForItem: (Int) -> AnyTorrentDetailViewModel?
    private let _contextMenuForItem: (Int) -> UIMenu?
    let base: Any

    var state: TorrentListViewState { _state() }
    var events: AnyPublisher<TorrentListEvent, Never> { _events() }

    init<Base>(_ base: Base) where
        Base: ViewModel,
        Base: EventEmitter,
        Base: TorrentListPreviewProvider,
        Base.Event == Event,
        Base.ViewEvent == ViewEvent,
        Base.ViewState == ViewState {
        self.base = base
        _events = { base.events }
        _state = { base.state }
        _handle = { base.handle($0) }
        _viewModelForItem = { base.detailViewModelForItem(at: $0) }
        _contextMenuForItem = { base.contextMenuForItem(at: $0) }
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
}

protocol TorrentListPreviewProvider: AnyObject {
    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel?
    func contextMenuForItem(at index: Int) -> UIMenu?
}

enum TorrentListEvent {
    case alert(Alert, source: PopoverSource?)
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
}

struct TorrentListViewState {
    var showAddButton: Bool = true
    var showFilterButton: Bool = true
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    var isLoading: AnyPublisher<Bool, Never>
    var hasActiveFilters: AnyPublisher<Bool, Never>
}
