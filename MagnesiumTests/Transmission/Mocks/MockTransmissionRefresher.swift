import Combine
@testable import Magnesium

final class MockTransmissionRefresher: TransmissionRefreshable {
    private(set) var refreshTransmissionCallCount = 0
    var refreshTransmissionResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func refreshTransmission() -> AnyPublisher<Void, TransmissionError> {
        refreshTransmissionCallCount += 1
        return refreshTransmissionResult
    }
}
