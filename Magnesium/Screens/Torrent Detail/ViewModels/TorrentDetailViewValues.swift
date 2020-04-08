import Combine
import CommonModels
import Foundation

struct TorrentDetailViewValues {
    var hash: String
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isRefreshing: AnyPublisher<Bool, Never>
    var contextMenu: (IndexPath) -> Menu?
}
