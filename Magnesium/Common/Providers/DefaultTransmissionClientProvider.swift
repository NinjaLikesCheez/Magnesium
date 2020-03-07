import Foundation

struct DefaultTransmissionClientProvider: TransmissionClientProvider {
    func createClient(baseURL: URL, username: String?, password: String?) -> TransmissionClient {
        return DefaultTransmissionClient(baseURL: baseURL, username: username, password: password)
    }
}
