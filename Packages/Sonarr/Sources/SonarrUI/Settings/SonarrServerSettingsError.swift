import Common

public enum SonarrServerSettingsError {
	case invalidState(message: String)
	case keychain(message: String)
	case unknown(message: String)
}

extension SonarrServerSettingsError: VisualError, Identifiable {
	public var id: Self { self }

	public var title: String {
		switch self {
		case .invalidState:
			"Couldn't Save Server"
		case .keychain:
			"Couldn't Save Settings"
		case .unknown:
			"Unknown Error Occurred"
		}
	}

	public var systemName: String {
		switch self {
		case .invalidState:
			"nosign"
		case .keychain:
			"person.badge.key"
		case .unknown:
			"questionmark"
		}
	}

	public var subtitle: String {
		switch self {
		case let .invalidState(message), let .keychain(message), let .unknown(message):
			message
		}
	}
}
