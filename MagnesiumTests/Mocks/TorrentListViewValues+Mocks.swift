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
        detailViewModel: @escaping (Int) -> AnyTorrentDetailViewModel = { _ in .init(MockDetailViewModel()) },
        contextMenu: @escaping (Int) -> Menu? = { _ in nil },
        leadingSwipeActionsConfiguration: @escaping (Int, PopoverSource)
            -> SwipeActionsConfiguration? = { _, _ in nil },
        trailingSwipeActionsConfiguration: @escaping (Int, PopoverSource)
            -> SwipeActionsConfiguration? = { _, _ in nil }
    ) -> Self {
        .init(
            title: Just(title).eraseToAnyPublisher(),
            items: Just(items).eraseToAnyPublisher(),
            isLoading: Just(isLoading).eraseToAnyPublisher(),
            isEditing: Just(isEditing).eraseToAnyPublisher(),
            hasActiveFilters: Just(hasActiveFilters).eraseToAnyPublisher(),
            editActionsEnabled: Just(editActionsEnabled).eraseToAnyPublisher(),
            status: Just(status).eraseToAnyPublisher(),
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
