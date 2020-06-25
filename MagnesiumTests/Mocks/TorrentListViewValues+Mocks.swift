import Combine
import CommonModels
@testable import Magnesium
import UIKit
import ViewModel
import XCTest

extension TorrentListViewValues {
    static func mock(
        title: String = "",
        items: [TorrentListItem] = [],
        isLoading: Bool = false,
        isEditing: Bool = false,
        hasActiveFilters: Bool = false,
        editActionsEnabled: Bool = false,
        status: String = "",
        detailViewModel: @escaping (TorrentListItem) -> AnyTorrentDetailViewModel = { _ in
            .init(MockDetailViewModel())
        },
        contextMenu: @escaping (TorrentListItem) -> Menu? = { _ in nil },
        leadingSwipeActionsConfiguration: @escaping (TorrentListItem, PopoverSource)
            -> SwipeActionsConfiguration? = { _, _ in nil },
        trailingSwipeActionsConfiguration: @escaping (TorrentListItem, PopoverSource)
            -> SwipeActionsConfiguration? = { _, _ in nil }
    ) -> Self {
        .init(
            title: Just(title).ui(),
            items: Just(items).ui(),
            isLoading: Just(isLoading).ui(),
            isEditing: Just(isEditing).ui(),
            hasActiveFilters: Just(hasActiveFilters).ui(),
            editActionsEnabled: Just(editActionsEnabled).ui(),
            status: Just(status).ui(),
            detailViewModel: detailViewModel,
            contextMenu: contextMenu,
            leadingSwipeActionsConfiguration: leadingSwipeActionsConfiguration,
            trailingSwipeActionsConfiguration: trailingSwipeActionsConfiguration
        )
    }
}

private final class MockDetailViewModel: ViewModel {
    let values = TorrentDetailViewValues.mock()
    let eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()
    func send(_ event: TorrentDetailViewEvent) {}
}
