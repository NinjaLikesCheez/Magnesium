import Foundation

struct DefaultDelugeClientProvider: DelugeClientProvider {
    func createClient(baseURL: URL, password: String) -> DelugeClient {
        return DefaultDelugeClient(baseURL: baseURL, password: password)
    }
}
