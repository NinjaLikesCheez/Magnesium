import Security

public enum KeychainError: Error {
	case system(SystemKeychainError)
}

/// Types of system keychain errors.
public enum SystemKeychainError: Error {
    /// The system keychain returned an unexpected status.
    case keychain(OSStatus)
    /// An unknown error occurred.
    case unknown
}
