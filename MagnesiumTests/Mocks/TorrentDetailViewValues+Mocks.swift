import Combine
@testable import Magnesium
import UIKit

extension TorrentDetailViewValues {
    static func mock(
        hash: String = "",
        sections: [TorrentDetailSection] = [],
        isRefreshing: Bool = false,
        contextMenu: @escaping (IndexPath) -> UIMenu? = { _ in nil }
    ) -> Self {
        .init(
            hash: hash,
            sections: Just(sections).eraseToAnyPublisher(),
            isRefreshing: Just(isRefreshing).eraseToAnyPublisher(),
            contextMenu: contextMenu
        )
    }
}
