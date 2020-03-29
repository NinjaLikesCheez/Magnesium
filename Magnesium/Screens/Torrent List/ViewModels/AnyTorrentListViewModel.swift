import Combine
import CommonModels
import UIKit
import ViewModel

final class AnyTorrentListViewModel: ViewModel, TorrentListProvider {
    private let _events: () -> AnyPublisher<Event, Never>
    private let _values: () -> ViewValues
    private let _receive: (ViewEvent) -> Void
    private let _viewModelForItem: (Int) -> AnyTorrentDetailViewModel?
    private let _contextMenuForItem: (Int) -> UIMenu?
    private let _leadingSwipeActionsConfigurationForItem: (Int, PopoverSource) -> SwipeActionsConfiguration?
    private let _trailingSwipeActionsConfigurationForItem: (Int, PopoverSource) -> SwipeActionsConfiguration?
    let base: Any

    var values: TorrentListViewValues { _values() }
    var events: AnyPublisher<TorrentListViewModelEvent, Never> { _events() }

    init<Base>(_ base: Base) where
        Base: ViewModel,
        Base: TorrentListProvider,
        Base.Event == Event,
        Base.ViewEvent == ViewEvent,
        Base.ViewValues == ViewValues {
        self.base = base
        _events = { base.events }
        _values = { base.values }
        _receive = { base.receive($0) }
        _viewModelForItem = { base.detailViewModelForItem(at: $0) }
        _contextMenuForItem = { base.contextMenuForItem(at: $0) }
        _leadingSwipeActionsConfigurationForItem = { base.leadingSwipeActionsConfigurationForItem(at: $0, source: $1) }
        _trailingSwipeActionsConfigurationForItem = {
            base.trailingSwipeActionsConfigurationForItem(at: $0, source: $1)
        }
    }

    func receive(_ event: TorrentListViewEvent) {
        _receive(event)
    }

    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        _viewModelForItem(index)
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        _contextMenuForItem(index)
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration? {
        _leadingSwipeActionsConfigurationForItem(index, source)
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> SwipeActionsConfiguration? {
        _trailingSwipeActionsConfigurationForItem(index, source)
    }
}
