import Foundation
import Combine
@testable import Magnesium

/// Mock implementation of Session for testing
class MockSession: ObservableObject {
    // MARK: - Mock Configuration
    
    @Published var server: Server?
    var actionImplementation: any TorrentClientActing = NullTorrentActionImplementation()
    
    var setServerResult: Result<Void, Session.Error> = .success(())
    var setServerCallCount = 0
    var setServerCalls: [Server] = []
    
    var resetCallCount = 0
    
    // MARK: - Session-like Interface
    
    func setServer(_ server: Server) throws(Session.Error) {
        setServerCallCount += 1
        setServerCalls.append(server)
        
        switch setServerResult {
        case .success:
            self.server = server
            // In a real implementation, this would create the appropriate action implementation
            // For testing, we can inject a mock
            return
        case .failure(let error):
            throw error
        }
    }
    
    func reset() {
        resetCallCount += 1
        server = nil
        actionImplementation = NullTorrentActionImplementation()
    }
    
    // MARK: - Test Helpers
    
    func setMockActionImplementation(_ implementation: any TorrentClientActing) {
        actionImplementation = implementation
    }
    
    func simulateMissingKeychainData(for server: Server) {
        setServerResult = .failure(.missingKeychainData(server: server))
    }
    
    func simulateDecodingError(_ error: Error) {
        setServerResult = .failure(.decodingFailed(error))
    }
    
    func simulateNotImplementedError() {
        setServerResult = .failure(.notImplemented)
    }
    
    func resetMock() {
        server = nil
        actionImplementation = NullTorrentActionImplementation()
        setServerResult = .success(())
        setServerCallCount = 0
        setServerCalls.removeAll()
        resetCallCount = 0
    }
}