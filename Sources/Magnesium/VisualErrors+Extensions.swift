//
//  VisualErrors+Extensions.swift
//  Magnesium
//
//  Created by ninji on 29/09/2025.
//
import Torrent
import Common
import APIClient

extension ClientError: @retroactive VisualError where ResponseError: VisualError {
	public var title: String {
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

	public var systemName: String {
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

	public var subtitle: String {
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

extension TorrentClientError: @retroactive VisualError {
	public var title: String {
		switch self {
		case .nullImplementation:
			return "Null Implementation"
		case .invalidLinkAdded:
			return "Invalid Link"
		case let .deluge(delugeError):
			return delugeError.title
		case let .qbittorrent(qbitError):
			return qbitError.title
		}
	}
	
	public var systemName: String {
		switch self {
		case .nullImplementation:
			return "exclamationmark.triangle"
		case .invalidLinkAdded:
			return "link"
		case let .deluge(delugeError):
			return delugeError.systemName
		case let .qbittorrent(qbitError):
			return qbitError.systemName
		}
	}
	
	public var subtitle: String {
		switch self {
		case .nullImplementation:
			return "No torrent client implementation is configured."
		case .invalidLinkAdded:
			return "The provided link is not a valid magnet or .torrent URL."
		case let .deluge(delugeError):
			return delugeError.subtitle
		case let .qbittorrent(qbitError):
			return qbitError.subtitle
		}
	}
	
	public func hash(into hasher: inout Hasher) {
		switch self {
		case .nullImplementation:
			hasher.combine("nullImplementation")
		case .invalidLinkAdded:
			hasher.combine("invalidLinkAdded")
		case let .deluge(delugeError):
			hasher.combine("deluge")
			hasher.combine(delugeError.title)
			hasher.combine(delugeError.subtitle)
			hasher.combine(delugeError.systemName)
		case let .qbittorrent(qbitError):
			hasher.combine("qbittorrent")
			hasher.combine(qbitError.title)
			hasher.combine(qbitError.subtitle)
			hasher.combine(qbitError.systemName)
		}
	}
}

// MARK: - Torrent client errors
// TODO: Move this into Torrent and make Deluge and QBittorrent errors equatable and hashable...
extension TorrentClientError: @retroactive Equatable {
	public static func == (lhs: TorrentClientError, rhs: TorrentClientError) -> Bool {
		switch (lhs, rhs) {
		case (.nullImplementation, .nullImplementation):
			true
		case (.invalidLinkAdded, .invalidLinkAdded):
			true
		case let (.deluge(lhsError), .deluge(rhsError)):
			lhsError == rhsError
		case let (.qbittorrent(lhsError), .qbittorrent(rhsError)):
			lhsError == rhsError
		default:
			false
		}
	}
}

