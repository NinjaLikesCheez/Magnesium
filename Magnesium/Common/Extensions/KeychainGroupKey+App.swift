import Foundation
import Keychain

extension KeychainGroupKey {
    static var servers: KeychainGroupKey {
        .init(class: kSecClassGenericPassword as String, service: "servers")
    }
}
