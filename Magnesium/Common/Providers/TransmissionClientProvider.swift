import Foundation

protocol TransmissionClientProvider {
    func createClient(baseURL: URL, username: String?, password: String?) -> TransmissionClient
}
