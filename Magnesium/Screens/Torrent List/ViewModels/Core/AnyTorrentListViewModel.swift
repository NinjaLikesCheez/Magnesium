import Combine
import UIKit
import ViewModel

final class AnyTorrentListViewModel: ViewModel, EventEmitter, TorrentListProvider {
    private let _events: () -> AnyPublisher<Event, Never>
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void
    private let _viewModelForItem: (Int) -> AnyTorrentDetailViewModel?
    private let _contextMenuForItem: (Int) -> UIMenu?
    private let _leadingSwipeActionsConfigurationForItem: (Int, PopoverSource) -> SwipeActionsConfiguration?
    private let _trailingSwipeActionsConfigurationForItem: (Int, PopoverSource) -> SwipeActionsConfiguration?
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

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration? {
        return _leadingSwipeActionsConfigurationForItem(index, source)
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> SwipeActionsConfiguration? {
        return _trailingSwipeActionsConfigurationForItem(index, source)
    }
}
