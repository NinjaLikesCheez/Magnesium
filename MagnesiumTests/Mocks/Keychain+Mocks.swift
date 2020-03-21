import Foundation
@testable import Magnesium

extension Keychain {
    class MockStore {
        var values = [String: Any]()
    }

    static var mock: Keychain { .mock(store: .init()) }

    static func mock(store: MockStore) -> Keychain {
        Keychain(
            fetchServerData: { store.values[$0.id] as? Data },
            updateServerData: { store.values[$0.id] = $0.keychainData },
            deleteServerData: { store.values.removeValue(forKey: $0.id) },
            deleteAllServerData: { store.values.removeAll() }
        )
    }
}
