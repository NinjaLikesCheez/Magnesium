import Deluge
import Foundation

protocol VisualError: Error, Equatable, Hashable {
	var title: String { get }
	var systemName: String { get }
	var subtitle: String { get }
}

extension KeychainError {
	var title: String {
		switch self {
		case .system:
			"Keychain Error"
		case .unknown:
			"Unknown Error"
		}
	}

	var systemName: String {
		switch self {
		case .system, .unknown:
			"key.slash"
		}
	}

	var subtitle: String {
		switch self {
		case let .system(status):
			"\(NSError(domain: NSOSStatusErrorDomain, code: Int(status)).localizedDescription)"
		case .unknown:
			"Please try again later"
		}
	}
}

extension AppPreferences.Error {
	var title: String {
		switch self {
		case let .keychain(error):
			error.title
		}
	}

	var systemName: String {
		switch self {
		case let .keychain(error):
			error.systemName
		}
	}

	var subtitle: String {
		switch self {
		case let .keychain(error):
			error.subtitle
		}
	}
}

extension Deluge.Error: VisualError {
	var title: String {
		switch self {
		case .encoding(_):
			"Failed to Encode"
		case .decoding(_):
			"Failed to Decode"
		case let .request(error):
			error.title
		case let .response(error):
			error.title
		}
	}

	var systemName: String {
		switch self {
		case let .encoding(error):
			"gear.badge.xmark"
		case .decoding(_):
			"gear.badge.xmark"
		case .request(_):
			"network.slash"
		case .response(_):
			"network.slash"
		}
	}

	var subtitle: String {
		switch self {
		case let .encoding(error):
			error.localizedDescription
		case let .decoding(error):
			error.localizedDescription
		case let .request(error):
			error.subtitle
		case let .response(error):
			error.subtitle
		}
	}
}

extension Deluge.ResponseError: @retroactive Hashable {}
extension Deluge.ResponseError: @retroactive Equatable {
	public static func == (lhs: Deluge.ResponseError, rhs: Deluge.ResponseError) -> Bool {
		switch (lhs, rhs) {
		case let (.message(lhsMessage), .message(rhsMessage)):
			lhsMessage == rhsMessage
		case (.unauthenticated, .unauthenticated):
			true
		case (.torrentAlreadyInSession, .torrentAlreadyInSession):
			true
		case let (.unknown(lhsError), .unknown(rhsError)):
			lhsError.localizedDescription == rhsError.localizedDescription
		default:
			false
		}
	}
}
extension Deluge.ResponseError: VisualError {
	var title: String {
		switch self {
		case .message:
			"Deluge Error"
		case .unauthenticated:
			"Couldn't Authenticate"
		case .unconnected:
			"Daemon Unconnected"
		case .torrentAlreadyInSession:
			"Torrent Already Exists"
		case .unknown:
			"Unknown Error"
		}
	}
	
	var systemName: String {
		switch self {
		case .message:
			"exclamationmark.triangle"
		case .unauthenticated:
			"lock.trianglebadge.exclamationmark"
		case .unconnected:
			"point.3.connected.trianglepath.dotted"
		case .torrentAlreadyInSession:
			"plus.square.on.square"
		case .unknown:
			"questionmark"
		}
	}
	
	var subtitle: String {
		switch self {
		case let .message(message):
			"\(message ?? "Unknown Error")"
		case .unauthenticated:
			"Please check your login details"
		case .unconnected:
			"Please connect the deluge daemon and try again"
		case .torrentAlreadyInSession:
			"Torrent already exists"
		case let .unknown(error):
			error.localizedDescription
		}
	}
}

extension DelugeRequestError: @retroactive Equatable {
	public static func == (lhs: DelugeRequestError, rhs: DelugeRequestError) -> Bool {
		switch (lhs, rhs) {
		case let (.urlError(lhsError), .urlError(rhsError)):
			lhsError.localizedDescription == rhsError.localizedDescription
		case let (.unknown(lhsError), .unknown(rhsError)):
			lhsError.localizedDescription == rhsError.localizedDescription
		default:
			false
		}
	}
}

extension DelugeRequestError: @retroactive Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .urlError(error):
			hasher.combine(0)
			hasher.combine(error.localizedDescription)
		case let .unknown(error):
			hasher.combine(1)
			hasher.combine(error.localizedDescription)
		}
	}
}

extension DelugeRequestError: VisualError {
	var title: String {
		switch self {
		case .urlError:
			"URL Error"
		case .unknown:
			"Unknown Error"
		}
	}

	var systemName: String {
		switch self {
		case .urlError:
			"network.slash"
		case .unknown:
			"questionmark"
		}
	}

	var subtitle: String {
		switch self {
		case let .urlError(error):
			error.localizedDescription
		case let .unknown(error):
			error.localizedDescription
		}
	}
}

extension TorrentClientError {
	var title: String {
		switch self {
		case .nullImplementation:
			"Null Implementation"
		case .invalidLinkAdded:
			"Invalid Link"
		case let .deluge(error):
			error.title
		}
	}

	var systemName: String {
		switch self {
		case .nullImplementation:
			"square.slash"
		case .invalidLinkAdded:
			"link"
		case let .deluge(error):
			error.systemName
		}
	}

	var subtitle: String {
		switch self {
		case .nullImplementation:
			"Null implementation called. This should only be used in testing"
		case .invalidLinkAdded:
			"The link was invalid. Please check it and try again"
		case let .deluge(error):
			error.subtitle
		}
	}
}

extension ServerSettingsError {
	var title: String {
		switch self {
		case .invalidState:
			"Couldn't Add Server"
		case .unableToAuthenticate:
			"Couldn't Authenticate"
		case .request:
			"Request Error"
		case .response:
			"Response Error"
		case .keychain:
			"Couldn't Save Settings"
		case .unknown:
			"Unknown Error Occurred"
		}
	}

	var systemName: String {
		switch self {
		case .invalidState:
			"nosign"
		case .unableToAuthenticate:
			"server.rack"
		case .request:
			"network.slash"
		case .response:
			"network.slash"
		case .unknown:
			"questionmark"
		case .keychain:
			"person.badge.key"
		}
	}

	var subtitle: String {
		switch self {
		case let .invalidState(message), let .request(message), let .response(message), let .keychain(message), let .unknown(message):
			message
		case let .unableToAuthenticate:
			"Please check your settings and try again"
		}
	}
}

