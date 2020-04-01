import Keychain
import Security

extension KeychainKey {
    static func server(_ server: Server) -> KeychainKey {
        .init(class: kSecClassGenericPassword as String, service: "servers", account: server.id)
    }
}
