//
//  VisualErrors+ClientError.swift
//  Torrent
//
//  Created by ninji on 29/09/2025.
//
import Common
import APIClient
import Foundation

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

