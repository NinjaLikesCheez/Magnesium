import Security

/// A keychain query.
public struct KeychainQuery: Equatable, Hashable {
    /// The class of the keychain item. This refers to the key `kSecClass`.
    public let `class`: String
    /// The service of the keychain item. This refers to the key `kSecAttrService`.
    public let service: String?
    /// The account of the keychain item. This refers to the key `kSecAttrAccount`.
    public let account: String?
    /// The accessibility of the keychain item. This refers to the key `kSecAttrAccessible`.
    public let accessibility: String?
    /// The access control settings for the keychain item. This refers to the key `kSecAttrAccessControl`.
    public let accessControl: AccessControl?

    /// Initializes a keychain item query.
    public init(
        class: String,
        service: String? = nil,
        account: String? = nil,
        accessibility: String? = nil,
        accessControl: AccessControl? = nil
    ) {
        self.class = `class`
        self.service = service
        self.account = account
        self.accessibility = accessibility
        self.accessControl = accessControl
    }
}

extension KeychainQuery {
    func rawQuery(with query: [String: Any] = [:]) -> [String: Any] {
        var rawQuery: [String: Any] = [
            kSecClass as String: `class`,
        ]

        if let service = service {
            rawQuery[kSecAttrService as String] = service
        }

        if let account = account {
            rawQuery[kSecAttrAccount as String] = account
        }

        if let accessibility = accessibility {
            rawQuery[kSecAttrAccessible as String] = accessibility
        }

        if let accessControl = accessControl {
            rawQuery[kSecAttrAccessControl as String] = accessControl.systemAccessControl
        }

        return rawQuery.merging(query, uniquingKeysWith: { old, _ in old })
    }

    func matches(query: KeychainQuery) -> Bool {
        `class` == query.class
            && (service == nil || service == query.service)
            && (account == nil || account == query.account)
            && (accessibility == nil || accessibility == query.accessibility)
            && (accessControl == nil || accessControl == query.accessControl)
    }
}

public extension KeychainQuery {
    /// Access control information for a keychain item.
    struct AccessControl {
        fileprivate let systemAccessControl: SecAccessControl
        /// The protection to be used for the keychain item.
        public let protection: CFString
        /// The flags specifying how the keychain item may be used.
        public let flags: SecAccessControlCreateFlags

        /// Initializes access control information.
        public init(protection: CFString, flags: SecAccessControlCreateFlags) {
            self.protection = protection
            self.flags = flags
            let accessControl = SecAccessControlCreateWithFlags(
                nil,
                protection,
                flags,
                nil
            )
            precondition(accessControl != nil)
            systemAccessControl = accessControl!
        }
    }
}

extension KeychainQuery.AccessControl: Equatable {
    public static func == (lhs: KeychainQuery.AccessControl, rhs: KeychainQuery.AccessControl) -> Bool {
        lhs.protection == rhs.protection && lhs.flags == rhs.flags
    }
}

extension KeychainQuery.AccessControl: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(protection)
        hasher.combine(flags.rawValue)
    }
}
