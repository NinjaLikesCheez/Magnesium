import Foundation
import SwiftUI
import Testing

@testable import TorrentCore

@Suite("StandardTorrentState Tests")
struct StandardTorrentStateTests {

	// MARK: - Enum Cases and String Representations Tests
	@Test("StandardTorrentState raw values")
	func torrentStateRawValues() {
		let expectations: [(StandardTorrentState, String)] = [
			(.downloading, "Downloading"),
			(.seeding, "Seeding"),
			(.paused, "Paused"),
			(.checking, "Checking"),
			(.queued, "Queued"),
			(.error, "Error"),
		]

		for (state, expectedRawValue) in expectations {
			#expect(state.rawValue == expectedRawValue)
		}
	}

	@Test("StandardTorrentState initialization from raw value")
	func torrentStateInitializationFromRawValue() {
		#expect(StandardTorrentState(rawValue: "Downloading") == .downloading)
		#expect(StandardTorrentState(rawValue: "Seeding") == .seeding)
		#expect(StandardTorrentState(rawValue: "Paused") == .paused)
		#expect(StandardTorrentState(rawValue: "Checking") == .checking)
		#expect(StandardTorrentState(rawValue: "Queued") == .queued)
		#expect(StandardTorrentState(rawValue: "Error") == .error)

		// Test invalid raw value
		#expect(StandardTorrentState(rawValue: "Invalid") == nil)
		#expect(StandardTorrentState(rawValue: "") == nil)
	}

	// MARK: - Localized String Tests

	@Test("StandardTorrentState localizedString returns non-empty values")
	func torrentStateLocalizedStringNonEmpty() {
		for state in StandardTorrentState.allCases {
			let localizedString = state.localizedString
			#expect(!localizedString.isEmpty, "Localized string for \(state) should not be empty")
		}
	}

	@Test("StandardTorrentState localizedString consistency")
	func torrentStateLocalizedStringConsistency() {
		// Test that calling localizedString multiple times returns the same value
		let state = StandardTorrentState.downloading
		let firstCall = state.localizedString
		let secondCall = state.localizedString

		#expect(firstCall == secondCall)
		#expect(!firstCall.isEmpty)
	}

	// MARK: - Progress Color Tests

	@Test("StandardTorrentState progressColor returns correct colors")
	func torrentStateProgressColors() {
		let expectations: [(StandardTorrentState, Color)] = [
			(.downloading, .blue),
			(.seeding, .green),
			(.paused, .purple),
			(.checking, .yellow),
			(.queued, .yellow),
			(.error, .red),
		]

		for (state, expectedColor) in expectations {
			#expect(state.progressColor == expectedColor)
		}
	}

	@Test("StandardTorrentState progressColor consistency")
	func torrentStateProgressColorConsistency() {
		// Test that calling progressColor multiple times returns the same value
		for state in StandardTorrentState.allCases {
			let firstCall = state.progressColor
			let secondCall = state.progressColor

			#expect(firstCall == secondCall, "Progress color for \(state) should be consistent")
		}
	}

	// MARK: - Codable Conformance Tests

	@Test("StandardTorrentState encoding to JSON")
	func torrentStateEncodingToJSON() throws {
		let encoder = JSONEncoder()

		for state in StandardTorrentState.allCases {
			let data = try encoder.encode(state)
			let jsonString = String(data: data, encoding: .utf8)

			#expect(jsonString != nil, "Should be able to encode \(state) to JSON")
			#expect(jsonString?.contains(state.rawValue) == true, "JSON should contain raw value for \(state)")
		}
	}

	@Test("StandardTorrentState decoding from JSON")
	func torrentStateDecodingFromJSON() throws {
		let decoder = JSONDecoder()

		for state in StandardTorrentState.allCases {
			let jsonString = "\"\(state.rawValue)\""
			let data = jsonString.data(using: .utf8)!

			let decodedState = try decoder.decode(StandardTorrentState.self, from: data)
			#expect(decodedState == state, "Should be able to decode \(state) from JSON")
		}
	}

	@Test("StandardTorrentState decoding invalid JSON")
	func torrentStateDecodingInvalidJSON() {
		let decoder = JSONDecoder()
		let invalidJSON = "\"InvalidState\""
		let data = invalidJSON.data(using: .utf8)!

		#expect(throws: DecodingError.self) {
			_ = try decoder.decode(StandardTorrentState.self, from: data)
		}
	}

	@Test("StandardTorrentState round-trip encoding and decoding")
	func torrentStateRoundTripEncodingDecoding() throws {
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()

		for originalState in StandardTorrentState.allCases {
			// Encode
			let encodedData = try encoder.encode(originalState)

			// Decode
			let decodedState = try decoder.decode(StandardTorrentState.self, from: encodedData)

			// Verify
			#expect(decodedState == originalState, "Round-trip should preserve \(originalState)")
		}
	}

	// MARK: - Identifiable Conformance Tests

	@Test("StandardTorrentState Identifiable conformance")
	func torrentStateIdentifiableConformance() {
		for state in StandardTorrentState.allCases {
			#expect(state.id == state, "id should return self for \(state)")
		}
	}

	@Test("StandardTorrentState id uniqueness")
	func torrentStateIdUniqueness() {
		let allIds = StandardTorrentState.allCases.map { $0.id }
		let uniqueIds = Set(allIds.map { $0.rawValue })

		#expect(allIds.count == uniqueIds.count, "All StandardTorrentState ids should be unique")
	}

	// MARK: - Equatable and Hashable Tests

	@Test("StandardTorrentState equality")
	func torrentStateEquality() {
		// Test equality
		#expect(StandardTorrentState.downloading == StandardTorrentState.downloading)
		#expect(StandardTorrentState.seeding == StandardTorrentState.seeding)

		// Test inequality
		#expect(StandardTorrentState.downloading != StandardTorrentState.seeding)
		#expect(StandardTorrentState.paused != StandardTorrentState.error)
	}

	@Test("StandardTorrentState hashing")
	func torrentStateHashing() {
		// Test that equal states have equal hash values
		let state1 = StandardTorrentState.downloading
		let state2 = StandardTorrentState.downloading

		#expect(state1 == state2)
		#expect(state1.hashValue == state2.hashValue)

		// Test with Set to ensure hashing works correctly
		let stateSet: Set<StandardTorrentState> = [.downloading, .downloading, .seeding]
		#expect(stateSet.count == 2)  // Should only contain 2 unique elements
		#expect(stateSet.contains(.downloading))
		#expect(stateSet.contains(.seeding))
	}

	@Test("StandardTorrentState hash consistency")
	func torrentStateHashConsistency() {
		// Test that hash values are consistent across multiple calls
		for state in StandardTorrentState.allCases {
			let firstHash = state.hashValue
			let secondHash = state.hashValue

			#expect(firstHash == secondHash, "Hash value for \(state) should be consistent")
		}
	}
}
