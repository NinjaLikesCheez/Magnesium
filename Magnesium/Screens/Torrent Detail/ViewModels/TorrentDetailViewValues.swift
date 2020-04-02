import Combine
import UIKit

struct TorrentDetailViewValues {
    var hash: String
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isRefreshing: AnyPublisher<Bool, Never>
    var contextMenu: (IndexPath) -> UIMenu?
}
