import Foundation
import TorrentCore
import TorrentPreferences

@testable import TorrentSession

/// Mock implementation of TorrentSessionProtocol for testing
final class MockTorrentSession: TorrentSessionProtocol {
	// MARK: - TorrentSessionProtocol Properties

	private(set) var server: TorrentServer?
	private(set) var client: any TorrentClient = NullTorrentClient()

	// MARK: - Mock Configuration

	var setServerResult: Result<Void, TorrentSession.Error> = .success(())
	var setServerCallCount = 0
	var setServerCalls: [TorrentServer] = []

	var resetCallCount = 0

	// MARK: - TorrentSessionProtocol Implementation

	init(_ preferences: TorrentPreferences) {}

	func setServer(_ server: TorrentServer) throws(TorrentSession.Error) {
		setServerCallCount += 1
		setServerCalls.append(server)

		switch setServerResult {
		case .success:
			self.server = server
			return
		case .failure(let error):
			throw error
		}
	}

	func reset() {
		resetCallCount += 1
		server = nil
		client = NullTorrentClient()
	}

	// MARK: - Test Helpers

	func setMockClient(_ client: any TorrentClient) {
		self.client = client
	}

	func simulateMissingKeychainData(for server: TorrentServer) {
		setServerResult = .failure(.missingKeychainData(server: server))
	}

	func simulateDecodingError(_ description: String) {
		setServerResult = .failure(.decodingFailed(description))
	}

	func simulateNotImplementedError() {
		setServerResult = .failure(.notImplemented)
	}

	func resetMock() {
		server = nil
		client = NullTorrentClient()
		setServerResult = .success(())
		setServerCallCount = 0
		setServerCalls.removeAll()
		resetCallCount = 0
	}
}
