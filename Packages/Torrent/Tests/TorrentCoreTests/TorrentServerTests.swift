import Foundation
import Testing

@testable import TorrentCore
@testable import TorrentTestSupport

@Suite("TorrentServer Tests")
struct TorrentServerTests {

	// MARK: - Initialization Tests

	@Test("Server initialization with all required properties")
	func serverInitializationWithAllProperties() {
		// Arrange
		let name = "Test Server"
		let type = TorrentServerType.deluge
		let data = "test data".data(using: .utf8)!
		let keychainData = "keychain data".data(using: .utf8)!

		// Act
		let server = TorrentServer(
			name: name,
			type: type,
			data: data,
			keychainData: keychainData
		)

		// Assert
		#expect(server.name == name)
		#expect(server.type == type)
		#expect(server.data == data)
		#expect(server.keychainData == keychainData)
		#expect(server.id == name)  // id should be the same as name
	}

	@Test("Server initialization with nil keychainData")
	func serverInitializationWithNilKeychainData() {
		// Arrange
		let name = "Test Server"
		let type = TorrentServerType.qbittorrent
		let data = "test data".data(using: .utf8)!

		// Act
		let server = TorrentServer(
			name: name,
			type: type,
			data: data,
			keychainData: nil
		)

		// Assert
		#expect(server.name == name)
		#expect(server.type == type)
		#expect(server.data == data)
		#expect(server.keychainData == nil)
		#expect(server.id == name)
	}

	@Test("Server initialization with different ServerTypes")
	func serverInitializationWithDifferentServerTypes() {
		let data = Data()

		for serverType in TorrentServerType.allCases {
			let server = TorrentServer(
				name: "Test \(serverType.rawValue)",
				type: serverType,
				data: data,
				keychainData: nil
			)

			#expect(server.type == serverType)
			#expect(server.name == "Test \(serverType.rawValue)")
		}
	}

	// MARK: - Codable Conformance Tests

	@Test("Server encoding to JSON")
	func serverEncodingToJSON() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Test Server",
			type: .deluge,
			data: "test data".data(using: .utf8)!,
			keychainData: "keychain data".data(using: .utf8)!
		)

		let encoder = JSONEncoder()

		// Act
		let encodedData = try encoder.encode(server)
		guard let jsonString = String(data: encodedData, encoding: .utf8) else {
			Issue.record("Failed to encode server to JSON")
			return
		}

		// Assert
		#expect(jsonString.contains("Test Server") == true)
		#expect(jsonString.contains("Deluge") == true)
		// keychainData should not be encoded (not in CodingKeys)
		#expect(jsonString.contains("keychain") == false)
	}

	@Test("Server decoding from JSON")
	func serverDecodingFromJSON() throws {
		// Arrange
		let originalServer = TestDataFactory.createServer(
			name: "Decode Test Server",
			type: .qbittorrent,
			data: "decode test data".data(using: .utf8)!
		)

		let encoder = JSONEncoder()
		let decoder = JSONDecoder()

		// Act
		let encodedData = try encoder.encode(originalServer)
		let decodedServer = try decoder.decode(TorrentServer.self, from: encodedData)

		// Assert
		#expect(decodedServer.name == originalServer.name)
		#expect(decodedServer.type == originalServer.type)
		#expect(decodedServer.data == originalServer.data)
		#expect(decodedServer.keychainData == nil)  // keychainData is not encoded/decoded
	}

	@Test("Server round-trip encoding and decoding")
	func serverRoundTripEncodingDecoding() throws {
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()

		for serverType in TorrentServerType.allCases {
			// Arrange
			let originalServer = TestDataFactory.createServer(
				name: "Round Trip \(serverType.rawValue)",
				type: serverType,
				data: "round trip data".data(using: .utf8)!
			)

			// Act
			let encodedData = try encoder.encode(originalServer)
			let decodedServer = try decoder.decode(TorrentServer.self, from: encodedData)

			// Assert
			#expect(decodedServer.name == originalServer.name)
			#expect(decodedServer.type == originalServer.type)
			#expect(decodedServer.data == originalServer.data)
		}
	}

	@Test("Server decoding with missing optional fields")
	func serverDecodingWithMissingOptionalFields() throws {
		// Arrange - JSON without keychainData (which is not encoded anyway)
		let jsonString = """
			{
					"name": "Minimal Server",
					"type": "Deluge",
					"data": "\("minimal data".data(using: .utf8)!.base64EncodedString())"
			}
			"""
		let jsonData = jsonString.data(using: .utf8)!
		let decoder = JSONDecoder()

		// Act
		let server = try decoder.decode(TorrentServer.self, from: jsonData)

		// Assert
		#expect(server.name == "Minimal Server")
		#expect(server.type == .deluge)
		#expect(server.keychainData == nil)
	}

	@Test("Server decoding with invalid ServerType")
	func serverDecodingWithInvalidServerType() {
		// Arrange
		let jsonString = """
			{
					"name": "Invalid Server",
					"type": "InvalidType",
					"data": "\("test data".data(using: .utf8)!.base64EncodedString())"
			}
			"""
		let jsonData = jsonString.data(using: .utf8)!
		let decoder = JSONDecoder()

		// Act & Assert
		#expect(throws: DecodingError.self) {
			_ = try decoder.decode(TorrentServer.self, from: jsonData)
		}
	}

	// MARK: - Identifiable Conformance Tests

	@Test("Server Identifiable conformance")
	func serverIdentifiableConformance() {
		let serverName = "Identifiable Test Server"
		let server = TestDataFactory.createServer(name: serverName)

		#expect(server.id == serverName)
		#expect(server.id == server.name)
	}

	@Test("Server id uniqueness based on name")
	func serverIdUniquenessBasedOnName() {
		let server1 = TestDataFactory.createServer(name: "Server 1")
		let server2 = TestDataFactory.createServer(name: "Server 2")
		let server3 = TestDataFactory.createServer(name: "Server 1")  // Same name as server1

		#expect(server1.id != server2.id)
		#expect(server1.id == server3.id)  // Same name = same id
	}

	// MARK: - Equality and Hashing Tests

	@Test("Server equality with all properties")
	func serverEqualityWithAllProperties() {
		let data = "test data".data(using: .utf8)!
		let keychainData = "keychain data".data(using: .utf8)!

		let server1 = TorrentServer(
			name: "Test Server",
			type: .deluge,
			data: data,
			keychainData: keychainData
		)

		let server2 = TorrentServer(
			name: "Test Server",
			type: .deluge,
			data: data,
			keychainData: keychainData
		)

		#expect(server1 == server2)
	}

	@Test("Server inequality with different properties")
	func serverInequalityWithDifferentProperties() {
		let baseServer = TestDataFactory.createServer(
			name: "Base Server",
			type: .deluge,
			data: "base data".data(using: .utf8)!
		)

		// Different name
		let differentNameServer = TorrentServer(
			name: "Different Server",
			type: baseServer.type,
			data: baseServer.data,
			keychainData: baseServer.keychainData
		)
		#expect(baseServer != differentNameServer)

		// Different type
		let differentTypeServer = TorrentServer(
			name: baseServer.name,
			type: .qbittorrent,
			data: baseServer.data,
			keychainData: baseServer.keychainData
		)
		#expect(baseServer != differentTypeServer)

		// Different data
		let differentDataServer = TorrentServer(
			name: baseServer.name,
			type: baseServer.type,
			data: "different data".data(using: .utf8)!,
			keychainData: baseServer.keychainData
		)
		#expect(baseServer != differentDataServer)

		// Different keychainData
		let differentKeychainServer = TorrentServer(
			name: baseServer.name,
			type: baseServer.type,
			data: baseServer.data,
			keychainData: "different keychain".data(using: .utf8)!
		)
		#expect(baseServer != differentKeychainServer)
	}

	@Test("Server equality with nil keychainData")
	func serverEqualityWithNilKeychainData() {
		let data = "test data".data(using: .utf8)!

		let server1 = TorrentServer(
			name: "Test Server",
			type: .deluge,
			data: data,
			keychainData: nil
		)

		let server2 = TorrentServer(
			name: "Test Server",
			type: .deluge,
			data: data,
			keychainData: nil
		)

		#expect(server1 == server2)
	}

	@Test("Server hashing consistency")
	func serverHashingConsistency() {
		let server1 = TestDataFactory.createServer(
			name: "Hash Test Server",
			type: .deluge,
			data: "hash test data".data(using: .utf8)!
		)

		let server2 = TestDataFactory.createServer(
			name: "Hash Test Server",
			type: .deluge,
			data: "hash test data".data(using: .utf8)!
		)

		// Equal servers should have equal hash values
		#expect(server1 == server2)
		#expect(server1.hashValue == server2.hashValue)

		// Test with Set to ensure hashing works correctly
		let serverSet: Set<TorrentServer> = [server1, server2]
		#expect(serverSet.count == 1)  // Should only contain one element due to equality
	}

	@Test("Server hashing with different properties")
	func serverHashingWithDifferentProperties() {
		let server1 = TestDataFactory.createServer(name: "Server 1")
		let server2 = TestDataFactory.createServer(name: "Server 2")

		// Different servers should (likely) have different hash values
		#expect(server1 != server2)

		// Test with Set
		let serverSet: Set<TorrentServer> = [server1, server2]
		#expect(serverSet.count == 2)  // Should contain both servers
		#expect(serverSet.contains(server1))
		#expect(serverSet.contains(server2))
	}

	// MARK: - Edge Cases Tests

	@Test("Server with empty name")
	func serverWithEmptyName() {
		let server = TestDataFactory.createServer(
			name: "",
			type: .deluge,
			data: Data()
		)

		#expect(server.name == "")
		#expect(server.id == "")  // id should be empty string
	}

	@Test("Server with empty data")
	func serverWithEmptyData() {
		let server = TestDataFactory.createServer(
			name: "Empty Data Server",
			data: Data()
		)

		#expect(server.data.isEmpty)
		#expect(server.name == "Empty Data Server")
	}

	@Test("Server with large data")
	func serverWithLargeData() {
		let largeData = Data(repeating: 0xFF, count: 1024 * 1024)  // 1MB of data
		let server = TestDataFactory.createServer(
			name: "Large Data Server",
			data: largeData
		)

		#expect(server.data.count == 1024 * 1024)
		#expect(server.name == "Large Data Server")
	}

	@Test("Server with Unicode characters")
	func serverWithUnicodeCharacters() {
		let unicodeName = "🖥️ Test Server 测试服务器"
		let unicodeData = "Unicode data: 🔐 测试数据".data(using: .utf8)!

		let server = TestDataFactory.createServer(
			name: unicodeName,
			data: unicodeData
		)

		#expect(server.name == unicodeName)
		#expect(server.id == unicodeName)
		#expect(server.data == unicodeData)
	}

	@Test("Server with special characters in name")
	func serverWithSpecialCharactersInName() {
		let specialName = "Server@#$%^&*()_+-=[]{}|;':\",./<>?"
		let server = TestDataFactory.createServer(name: specialName)

		#expect(server.name == specialName)
		#expect(server.id == specialName)
	}
}
