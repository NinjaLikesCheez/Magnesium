import Combine

protocol DelugeRefreshable {
    func refreshDeluge() -> AnyPublisher<Void, DelugeError>
}
