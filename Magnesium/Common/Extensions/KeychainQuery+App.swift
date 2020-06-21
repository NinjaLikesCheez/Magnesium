import Keychain
import Security

extension KeychainQuery {
    static var servers: Self {
        .init(class: kSecClassGenericPassword as String, service: "servers")
    }

    static func server(_ server: Server) -> Self {
        .init(class: kSecClassGenericPassword as String, service: "servers", account: server.id)
    }
}
