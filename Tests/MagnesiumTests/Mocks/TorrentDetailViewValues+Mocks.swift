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
            sections: Just(sections).ui(),
            isRefreshing: Just(isRefreshing).ui(),
            toolbarInfo: Just(toolbarInfo).ui(),
            editSection: Just(editSection).ui(),
            contextMenu: contextMenu
        )
    }
}
