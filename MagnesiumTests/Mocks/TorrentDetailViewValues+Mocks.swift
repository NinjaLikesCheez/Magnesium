import Combine
import CommonModels
@testable import Magnesium
import UIKit

extension TorrentDetailViewValues {
    static func mock(
        hash: String = "",
        sections: [TorrentDetailSection] = [],
        isRefreshing: Bool = false,
        editSection: TorrentDetailSectionType? = nil,
        toolbarInfo: String = "",
        contextMenu: @escaping (IndexPath) -> Menu? = { _ in nil }
    ) -> Self {
        .init(
            hash: hash,
            sections: Just(sections).eraseToAnyPublisher(),
            isRefreshing: Just(isRefreshing).eraseToAnyPublisher(),
            toolbarInfo: Just(toolbarInfo).eraseToAnyPublisher(),
            editSection: Just(editSection).eraseToAnyPublisher(),
            contextMenu: contextMenu
        )
    }
}
