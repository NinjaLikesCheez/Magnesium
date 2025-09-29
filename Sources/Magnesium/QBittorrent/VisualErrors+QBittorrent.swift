//
//  VisualErrors+Extensions.swift
//  Magnesium
//
//  Created by ninji on 29/09/2025.
//
import Common
import QBittorrent

// MARK: - QBittorrent procotol extensions
extension QBittorrent.ResponseError: @retroactive Equatable {
	public static func == (lhs: QBittorrent.ResponseError, rhs: QBittorrent.ResponseError) -> Bool {
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

extension QBittorrent.ResponseError: @retroactive Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .message(message):
			hasher.combine(0)
			hasher.combine(message)
		case .unauthenticated:
			hasher.combine(1)
		case .torrentAlreadyInSession:
			hasher.combine(2)
		case let .unknown(error):
			hasher.combine(3)
			hasher.combine(error.localizedDescription)
		case .conflict:
			hasher.combine(4)
		case .fails:
			hasher.combine(5)
		}
	}
}

// MARK: - QBittorrent Visual Errors
extension QBittorrent.ResponseError: @retroactive VisualError {
	public var title: String {
		switch self {
		case .message:
			"Deluge Error"
		case .unauthenticated:
			"Couldn't Authenticate"
		case .torrentAlreadyInSession:
			"Torrent Already Exists"
		case .unknown:
			"Unknown Error"
		case .conflict:
			"Conflict"
		case .fails:
			"Failed"
		}
	}

	public var systemName: String {
		switch self {
		case .message:
			"exclamationmark.triangle"
		case .unauthenticated:
			"lock.trianglebadge.exclamationmark"
		case .torrentAlreadyInSession:
			"plus.square.on.square"
		case .unknown:
			"questionmark"
		case .conflict:
			"rectangle.on.rectangle.slash"
		case .fails:
			"nosign"
		}
	}

	public var subtitle: String {
		switch self {
		case let .message(message):
			"\(message ?? "Unknown Error")"
		case .unauthenticated:
			"Please check your login details"
		case .torrentAlreadyInSession:
			"Torrent already exists"
		case let .unknown(error):
			error.localizedDescription
		case .conflict:
			"An unknown error occurred: 409 Conflict"
		case .fails:
			"Action failed. Please check and try again"
		}
	}
}
