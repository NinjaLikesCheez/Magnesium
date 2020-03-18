import Combine
import Deluge

protocol TorrentRefresher {
    func refreshTorrents() -> AnyPublisher<Void, Error>
}
