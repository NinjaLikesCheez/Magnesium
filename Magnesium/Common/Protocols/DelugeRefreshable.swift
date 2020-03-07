import Combine
import Deluge

protocol DelugeRefreshable {
    func refreshDeluge() -> AnyPublisher<Void, DelugeError>
}
