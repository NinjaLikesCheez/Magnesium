import Combine

protocol TorrentRefresher {
    func refreshTorrents() -> AnyPublisher<Void, Error>
}
