import Foundation

protocol DelugeClientProvider {
    func createClient(baseURL: URL, password: String) -> DelugeClient
}

struct DefaultDelugeClientProvider: DelugeClientProvider {
    func createClient(baseURL: URL, password: String) -> DelugeClient {
        return DefaultDelugeClient(baseURL: baseURL, password: password)
    }
}
