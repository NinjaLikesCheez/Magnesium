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

extension ClientError: @retroactive Hashable where ResponseError: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .encoding(error):
			hasher.combine(0)
			hasher.combine(error.localizedDescription)
		case let .decoding(error):
			hasher.combine(1)
			hasher.combine(error.localizedDescription)
		case let .request(requestError):
			hasher.combine(2)
			hasher.combine(requestError)
		case let .response(responseError):
			hasher.combine(3)
			hasher.combine(responseError)
		}
	}
}

extension ClientError: @retroactive Equatable where ResponseError: Equatable {
	public static func == (lhs: ClientError<ResponseError>, rhs: ClientError<ResponseError>) -> Bool {
		switch (lhs, rhs) {
		case let (.encoding(lhsError), .encoding(rhsError)):
			return lhsError.localizedDescription == rhsError.localizedDescription
		case let (.decoding(lhsError), .decoding(rhsError)):
			return lhsError.localizedDescription == rhsError.localizedDescription
		case let (.request(lhsRequest), .request(rhsRequest)):
			return lhsRequest == rhsRequest
		case let (.response(lhsResponse), .response(rhsResponse)):
			return lhsResponse == rhsResponse
		default:
			return false
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
		case .encoding:
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

extension Deluge.ResponseError: @retroactive Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .message(message):
			hasher.combine(0)
			hasher.combine(message)
		case .unauthenticated:
			hasher.combine(1)
		case .unconnected:
			hasher.combine(2)
		case .torrentAlreadyInSession:
			hasher.combine(3)
		case let .unknown(error):
			hasher.combine(4)
			hasher.combine(error.localizedDescription)
		}
	}
}
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

extension RequestError: @retroactive Equatable {
	public static func == (lhs: RequestError, rhs: RequestError) -> Bool {
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

extension RequestError: @retroactive Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .urlError(error):
			hasher.combine(0)
			hasher.combine(error.localizedDescription)
		case let .unknown(error):
			hasher.combine(1)
			hasher.combine(error.localizedDescription)
		case let .invalidRequest(error):
			hasher.combine(2)
			hasher.combine(error.localizedDescription)
		}
	}
}

extension RequestError: VisualError {
	var title: String {
		switch self {
		case .urlError:
			"URL Error"
		case .unknown:
			"Unknown Error"
		case .invalidRequest:
			"Invalid Request"
		}
	}

	var systemName: String {
		switch self {
		case .urlError:
			"network.slash"
		case .unknown, .invalidRequest:
			"questionmark"
		}
	}

	var subtitle: String {
		switch self {
		case let .urlError(error):
			error.localizedDescription
		case let .unknown(error):
			error.localizedDescription
		case let .invalidRequest(error):
			error.localizedDescription
		}
	}
}

extension TorrentClientError: Equatable {
	public static func == (lhs: TorrentClientError, rhs: TorrentClientError) -> Bool {
		switch (lhs, rhs) {
		case (.nullImplementation, .nullImplementation):
			return true
		case (.invalidLinkAdded, .invalidLinkAdded):
			return true
		case let (.deluge(lhsError), .deluge(rhsError)):
			return lhsError == rhsError
		default:
			return false
		}
	}
}

extension TorrentClientError: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case .nullImplementation:
			hasher.combine(0)
		case .invalidLinkAdded:
			hasher.combine(1)
		case .deluge(let error):
			hasher.combine(2)
			hasher.combine(error)
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
		case let .invalidState(message), let .request(message), let .response(message), let .keychain(message),
			let .unknown(message):
			message
		case .unableToAuthenticate:
			"Please check your settings and try again"
		}
	}
}
