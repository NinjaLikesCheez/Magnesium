import Combine

struct TorrentDetailViewRepresentation {
    var hash: String
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isRefreshing: AnyPublisher<Bool, Never>
}
