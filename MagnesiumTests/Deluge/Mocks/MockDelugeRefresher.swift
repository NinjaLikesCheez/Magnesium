import Combine
@testable import Magnesium

final class MockDelugeRefresher: DelugeRefreshable {
    private(set) var refreshDelugeCallCount = 0
    var refreshDelugeResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func refreshDeluge() -> AnyPublisher<Void, DelugeError> {
        refreshDelugeCallCount += 1
        return refreshDelugeResult
    }
}
