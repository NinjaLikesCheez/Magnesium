import Combine
import CommonModels
import Foundation

struct TorrentDetailViewValues {
    var hash: String
    var sections: UIPublisher<[TorrentDetailSection]>
    var isRefreshing: UIPublisher<Bool>
    var toolbarInfo: UIPublisher<String>
    var editSection: UIPublisher<TorrentDetailSectionType?>
    var contextMenu: (IndexPath) -> Menu?
}
