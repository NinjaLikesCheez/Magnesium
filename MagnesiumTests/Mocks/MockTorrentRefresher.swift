import Combine
@testable import Magnesium

final class MockTorrentRefresher: TorrentRefresher {
    private(set) var refreshTorrentsCallCount = 0
    var refreshTorrentsResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func refreshTorrents() -> AnyPublisher<Void, Error> {
        refreshTorrentsCallCount += 1
        return refreshTorrentsResult
    }
}
