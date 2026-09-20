import Foundation

/// Lightweight hook for reporting unexpected failures to an external service (e.g. Sentry).
///
/// Packages call ``capture(_:feature:operation:)`` on error paths; the app wires ``handler`` at
/// launch. When unset (tests, previews), reporting is a no-op.
public enum ErrorReporting {
	public struct Context: Sendable {
		public var feature: String
		public var operation: String?

		public init(feature: String, operation: String? = nil) {
			self.feature = feature
			self.operation = operation
		}
	}

	/// Invoked for each reported error. Set once at app launch; left `nil` in tests.
	nonisolated(unsafe) public static var handler: (@Sendable (any Error, Context) -> Void)?

	/// Reports an error with a coarse feature tag and optional operation name for grouping.
	public static func capture(_ error: some Error, feature: String, operation: String? = nil) {
		handler?(error, Context(feature: feature, operation: operation))
	}
}
