//
//  VisualErrors+Extensions.swift
//  Magnesium
//
//  Created by ninji on 22/09/2025.
//
import Deluge
import Common

// MARK: - Deluge errors
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
		case .unknownMethod:
			hasher.combine(5)
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
extension Deluge.ResponseError: @retroactive VisualError {
	public var title: String {
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
		case .unknownMethod:
			"Unknown Method"
		}
	}

	public var systemName: String {
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
		case .unknownMethod:
			"questionmark.circle.dashed"
		}
	}

	public var subtitle: String {
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
		case .unknownMethod:
			"Please file feedback by shaking the device"
		}
	}
}

// MARK: - Request errors
extension RequestError: @retroactive VisualError {
	public var title: String {
		switch self {
		case .urlError:
			"URL Error"
		case .unknown:
			"Unknown Error"
		case .invalidRequest:
			"Invalid Request"
		}
	}

	public var systemName: String {
		switch self {
		case .urlError:
			"network.slash"
		case .unknown, .invalidRequest:
			"questionmark"
		}
	}

	public var subtitle: String {
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

// TODO: Move into API Client
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

// TODO: Move into API Client
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

