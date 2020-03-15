import Combine
import Transmission

protocol TransmissionRefreshable {
    func refreshTransmission() -> AnyPublisher<Void, TransmissionError>
}
