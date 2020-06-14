import Combine
import CommonModels
import Foundation

struct TorrentDetailViewValues {
    var hash: String
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isRefreshing: AnyPublisher<Bool, Never>
    var toolbarInfo: AnyPublisher<String, Never>
    var editSection: AnyPublisher<TorrentDetailSectionType?, Never>
    var contextMenu: (IndexPath) -> Menu?
}
