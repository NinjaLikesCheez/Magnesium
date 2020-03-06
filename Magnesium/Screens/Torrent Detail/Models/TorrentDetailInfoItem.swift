import Combine

struct TorrentDetailInfoItem: Identifiable {
    var name: String
    var value: AnyPublisher<String, Never>
    var expandedValue: AnyPublisher<String, Never>?

    var id: String {
        return name
    }
}
