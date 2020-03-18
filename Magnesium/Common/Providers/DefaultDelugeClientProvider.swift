import Foundation

struct DefaultDelugeClientProvider: DelugeClientProvider {
    func createClient(baseURL: URL, password: String) -> DelugeClient {
        DefaultDelugeClient(baseURL: baseURL, password: password)
    }
}
