import Foundation

protocol DelugeClientProvider {
    func createClient(baseURL: URL, password: String) -> DelugeClient
}
