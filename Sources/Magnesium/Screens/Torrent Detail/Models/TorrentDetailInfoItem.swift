import Combine

struct TorrentDetailInfoItem: Equatable, Hashable {
    var name: String
    var value: UIPublisher<String>
    var expandedValue: UIPublisher<String>?

    var id: String {
        name
    }
}
