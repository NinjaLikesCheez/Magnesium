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
    var readError: Error?
    var writeError: Error?
    var deleteError: Error?
    
    // MARK: - Change Publisher
    
    private let changeSubject = PassthroughSubject<KeychainChange, Never>()
    
    var changePublisher: AnyPublisher<KeychainChange, Never> {
        changeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Keychain Implementation
    
    func data(for query: KeychainQuery) throws -> Data? {
        if shouldFailOnRead {
            throw readError ?? MockKeychainError.readFailed
        }
        
        let key = makeKey(from: query)
        return storage[key]
    }
    
    func set(_ data: Data, for query: KeychainQuery) throws {
        if shouldFailOnWrite {
            throw writeError ?? MockKeychainError.writeFailed
        }
        
        let key = makeKey(from: query)
        let oldValue = storage[key]
        storage[key] = data

        // Publish change
			if oldValue == nil {
				changeSubject.send(KeychainChange.updated(query, data))
			}
    }
    
    func removeData(for query: KeychainQuery) throws {
        if shouldFailOnDelete {
            throw deleteError ?? MockKeychainError.deleteFailed
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

// MARK: - Mock Keychain Errors

enum MockKeychainError: Error, LocalizedError {
    case readFailed
    case writeFailed
    case deleteFailed
    case itemNotFound
    case duplicateItem
    case invalidParameters
    
    var errorDescription: String? {
        switch self {
        case .readFailed:
            return "Failed to read from keychain"
        case .writeFailed:
            return "Failed to write to keychain"
        case .deleteFailed:
            return "Failed to delete from keychain"
        case .itemNotFound:
            return "Keychain item not found"
        case .duplicateItem:
            return "Duplicate keychain item"
        case .invalidParameters:
            return "Invalid keychain parameters"
        }
    }
}
