import Combine

protocol TransmissionRefreshable {
    func refreshTransmission() -> AnyPublisher<Void, TransmissionError>
}
