import Foundation
import SwiftUI
import Testing
@testable import Magnesium

@Suite("TorrentState Tests")
struct TorrentStateTests {

	// MARK: - Enum Cases and String Representations Tests
	@Test("TorrentState raw values", arguments: [
		(TorrentState.downloading, "Downloading"),
		(TorrentState.seeding, "Seeding"),
		(TorrentState.paused, "Paused"),
		(TorrentState.checking, "Checking"),
		(TorrentState.queued, "Queued"),
		(TorrentState.error, "Error")
	])
	func torrentStateRawValues(state: TorrentState, expectedRawValue: String) {
		#expect(state.rawValue == expectedRawValue)
	}

	@Test("TorrentState initialization from raw value")
	func torrentStateInitializationFromRawValue() {
		#expect(TorrentState(rawValue: "Downloading") == .downloading)
		#expect(TorrentState(rawValue: "Seeding") == .seeding)
		#expect(TorrentState(rawValue: "Paused") == .paused)
		#expect(TorrentState(rawValue: "Checking") == .checking)
		#expect(TorrentState(rawValue: "Queued") == .queued)
		#expect(TorrentState(rawValue: "Error") == .error)

		// Test invalid raw value
		#expect(TorrentState(rawValue: "Invalid") == nil)
		#expect(TorrentState(rawValue: "") == nil)
	}

	// MARK: - Localized String Tests

	@Test("TorrentState localizedString returns non-empty values")
	func torrentStateLocalizedStringNonEmpty() {
		for state in TorrentState.allCases {
			let localizedString = state.localizedString
			#expect(!localizedString.isEmpty, "Localized string for \(state) should not be empty")
		}
	}

	@Test("TorrentState localizedString consistency")
	func torrentStateLocalizedStringConsistency() {
		// Test that calling localizedString multiple times returns the same value
		let state = TorrentState.downloading
		let firstCall = state.localizedString
		let secondCall = state.localizedString

		#expect(firstCall == secondCall)
		#expect(!firstCall.isEmpty)
	}

	// MARK: - Progress Color Tests

	@Test("TorrentState progressColor returns correct colors", arguments: [
		(TorrentState.downloading, Color.blue),
		(TorrentState.seeding, Color.green),
		(TorrentState.paused, Color.purple),
		(TorrentState.checking, Color.yellow),
		(TorrentState.queued, Color.yellow),
		(TorrentState.error, Color.red)
	])
	func torrentStateProgressColors(state: TorrentState, expectedColor: Color) {
		#expect(state.progressColor == expectedColor)
	}

	@Test("TorrentState progressColor consistency")
	func torrentStateProgressColorConsistency() {
		// Test that calling progressColor multiple times returns the same value
		for state in TorrentState.allCases {
			let firstCall = state.progressColor
			let secondCall = state.progressColor

			#expect(firstCall == secondCall, "Progress color for \(state) should be consistent")
		}
	}

	// MARK: - Codable Conformance Tests

	@Test("TorrentState encoding to JSON")
	func torrentStateEncodingToJSON() throws {
		let encoder = JSONEncoder()

		for state in TorrentState.allCases {
			let data = try encoder.encode(state)
			let jsonString = String(data: data, encoding: .utf8)

			#expect(jsonString != nil, "Should be able to encode \(state) to JSON")
			#expect(jsonString?.contains(state.rawValue) == true, "JSON should contain raw value for \(state)")
		}
	}

	@Test("TorrentState decoding from JSON")
	func torrentStateDecodingFromJSON() throws {
		let decoder = JSONDecoder()

		for state in TorrentState.allCases {
			let jsonString = "\"\(state.rawValue)\""
			let data = jsonString.data(using: .utf8)!

			let decodedState = try decoder.decode(TorrentState.self, from: data)
			#expect(decodedState == state, "Should be able to decode \(state) from JSON")
		}
	}

	@Test("TorrentState decoding invalid JSON")
	func torrentStateDecodingInvalidJSON() {
		let decoder = JSONDecoder()
		let invalidJSON = "\"InvalidState\""
		let data = invalidJSON.data(using: .utf8)!

		#expect(throws: DecodingError.self) {
			_ = try decoder.decode(TorrentState.self, from: data)
		}
	}

	@Test("TorrentState round-trip encoding and decoding")
	func torrentStateRoundTripEncodingDecoding() throws {
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()

		for originalState in TorrentState.allCases {
			// Encode
			let encodedData = try encoder.encode(originalState)

			// Decode
			let decodedState = try decoder.decode(TorrentState.self, from: encodedData)

			// Verify
			#expect(decodedState == originalState, "Round-trip should preserve \(originalState)")
		}
	}

	// MARK: - Identifiable Conformance Tests

	@Test("TorrentState Identifiable conformance")
	func torrentStateIdentifiableConformance() {
		for state in TorrentState.allCases {
			#expect(state.id == state, "id should return self for \(state)")
		}
	}

	@Test("TorrentState id uniqueness")
	func torrentStateIdUniqueness() {
		let allIds = TorrentState.allCases.map { $0.id }
		let uniqueIds = Set(allIds.map { $0.rawValue })

		#expect(allIds.count == uniqueIds.count, "All TorrentState ids should be unique")
	}

	// MARK: - Equatable and Hashable Tests

	@Test("TorrentState equality")
	func torrentStateEquality() {
		// Test equality
		#expect(TorrentState.downloading == TorrentState.downloading)
		#expect(TorrentState.seeding == TorrentState.seeding)

		// Test inequality
		#expect(TorrentState.downloading != TorrentState.seeding)
		#expect(TorrentState.paused != TorrentState.error)
	}

	@Test("TorrentState hashing")
	func torrentStateHashing() {
		// Test that equal states have equal hash values
		let state1 = TorrentState.downloading
		let state2 = TorrentState.downloading

		#expect(state1 == state2)
		#expect(state1.hashValue == state2.hashValue)

		// Test with Set to ensure hashing works correctly
		let stateSet: Set<TorrentState> = [.downloading, .downloading, .seeding]
		#expect(stateSet.count == 2) // Should only contain 2 unique elements
		#expect(stateSet.contains(.downloading))
		#expect(stateSet.contains(.seeding))
	}

	@Test("TorrentState hash consistency")
	func torrentStateHashConsistency() {
		// Test that hash values are consistent across multiple calls
		for state in TorrentState.allCases {
			let firstHash = state.hashValue
			let secondHash = state.hashValue

			#expect(firstHash == secondHash, "Hash value for \(state) should be consistent")
		}
	}
}
