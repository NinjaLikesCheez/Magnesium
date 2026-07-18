import Foundation

/// Types of keychain changes that can occur.
public enum KeychainChange {
	/// A keychain item was updated.
	case updated(KeychainQuery, Data)
	/// Keychain items matching the query were deleted.
	case deleted(KeychainQuery)

	/// Returns whether the given query matches the changed query.
	/// - Parameter query: The keychain query to check for matches.
	public func matches(query: KeychainQuery) -> Bool {
		switch self {
		case let .updated(updatedQuery, _):
			return query.matches(query: updatedQuery)
		case let .deleted(updatedQuery):
			return query.matches(query: updatedQuery)
		}
	}
}
