import Foundation
import Combine
@testable import Magnesium

/// Mock implementation of Keychain for testing
class MockKeychain: Keychain {
	
	// MARK: - Mock Storage

	private var storage: [String: Data] = [:]
	private var accessGroups: [String: String] = [:]

	// MARK: - Mock Configuration

	var shouldFailOnRead = false
	var shouldFailOnWrite = false
	var shouldFailOnDelete = false
	var readError: KeychainError?
	var writeError: KeychainError?
	var deleteError: KeychainError?

	// MARK: - Change Publisher

	private let changeSubject = PassthroughSubject<KeychainChange, Never>()

	var changePublisher: AnyPublisher<KeychainChange, Never> {
		changeSubject.eraseToAnyPublisher()
	}

	// MARK: - Keychain Implementation

	func data(for query: KeychainQuery) throws(KeychainError) -> Data? {
		if shouldFailOnRead {
			throw readError ?? KeychainError.system(OSStatus(1))
		}

		let key = makeKey(from: query)
		return storage[key]
	}

	func set(_ data: Data, for query: KeychainQuery) throws(KeychainError) {
		if shouldFailOnWrite {
			throw writeError ?? KeychainError.system(OSStatus(1))
		}

		let key = makeKey(from: query)
		let oldValue = storage[key]
		storage[key] = data

		// Publish change
		changeSubject.send(KeychainChange.updated(query, data))
	}

	func removeData(for query: KeychainQuery) throws(KeychainError) {
		if shouldFailOnDelete {
			throw deleteError ?? KeychainError.system(OSStatus(1))
		}

		let key = makeKey(from: query)
		let oldValue = storage.removeValue(forKey: key)
		accessGroups.removeValue(forKey: key)

		if oldValue != nil {
			let change = KeychainChange.deleted(query)
			changeSubject.send(change)
		}
	}

	// MARK: - Test Helpers

	func reset() {
		storage.removeAll()
		accessGroups.removeAll()
		shouldFailOnRead = false
		shouldFailOnWrite = false
		shouldFailOnDelete = false
		readError = nil
		writeError = nil
		deleteError = nil
	}

	func contains(key: String) -> Bool {
		return storage.keys.contains { $0.contains(key) }
	}

	func getAllKeys() -> [String] {
		return Array(storage.keys)
	}

	func getStorageCount() -> Int {
		return storage.count
	}

	func simulateKeychainError() {
		shouldFailOnRead = true
		shouldFailOnWrite = true
		shouldFailOnDelete = true
	}

	func simulateReadOnlyMode() {
		shouldFailOnWrite = true
		shouldFailOnDelete = true
	}

	// MARK: - Private Helpers

	private func makeKey(from query: KeychainQuery) -> String {
		var components: [String] = []

		if let service = query.service {
			components.append("service:\(service)")
		}

		if let account = query.account {
			components.append("account:\(account)")
		}

		return components.joined(separator: "|")
	}
}

