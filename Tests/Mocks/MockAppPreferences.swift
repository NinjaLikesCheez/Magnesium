import Foundation
import Combine
@testable import Magnesium

/// Mock implementation of AppPreferences for testing
class MockAppPreferences: ObservableObject {
    // MARK: - Mock Storage
    
    @Published var autoRefreshInterval: TimeInterval = 2.0
    @Published var servers: [Server] = []
    @Published var selectedServerID: String?
    @Published var sortOption: SortOption = .init(property: .dateAdded)
    @Published var filterOptions: FilterOptions = .init()
    @Published var automaticallyLookForMagnetLinks: Bool = false
    
    // MARK: - Mock Configuration
    
    var getSelectedServerResult: Result<Server?, Error> = .success(nil)
    var getSelectedServerCallCount = 0
    
    var getServersResult: Result<[Server], Error> = .success([])
    var getServersCallCount = 0
    
    var addOrUpdateResult: Result<Void, Error> = .success(())
    var addOrUpdateCallCount = 0
    var addOrUpdateCalls: [Server] = []
    
    var removeResult: Result<Void, Error> = .success(())
    var removeCallCount = 0
    var removeCalls: [Server] = []
    
    var removeServersResult: Result<Void, Error> = .success(())
    var removeServersCallCount = 0
    
    var resetCallCount = 0
    
    // MARK: - AppPreferences-like Interface
    
    func getSelectedServer() throws -> Server? {
        getSelectedServerCallCount += 1
        
        switch getSelectedServerResult {
        case .success(let server):
            return server
        case .failure(let error):
            throw error
        }
    }
    
    func getServers() throws -> [Server] {
        getServersCallCount += 1
        
        switch getServersResult {
        case .success(let servers):
            return servers
        case .failure(let error):
            throw error
        }
    }
    
    func addOrUpdate(server: Server) throws {
        addOrUpdateCallCount += 1
        addOrUpdateCalls.append(server)
        
        switch addOrUpdateResult {
        case .success:
            // Update mock storage
            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                servers[index] = server
            } else {
                servers.append(server)
            }
            return
        case .failure(let error):
            throw error
        }
    }
    
    func remove(server: Server) throws {
        removeCallCount += 1
        removeCalls.append(server)
        
        switch removeResult {
        case .success:
            servers.removeAll { $0.id == server.id }
            if selectedServerID == server.id {
                selectedServerID = servers.first?.id
            }
            return
        case .failure(let error):
            throw error
        }
    }
    
    func removeServers() throws {
        removeServersCallCount += 1
        
        switch removeServersResult {
        case .success:
            servers.removeAll()
            selectedServerID = nil
            return
        case .failure(let error):
            throw error
        }
    }
    
    func reset() {
        resetCallCount += 1
        autoRefreshInterval = 2.0
        servers.removeAll()
        selectedServerID = nil
        sortOption = .init(property: .dateAdded)
        filterOptions = .init()
        automaticallyLookForMagnetLinks = false
    }
    
    // MARK: - Test Helpers
    
    func setMockServers(_ servers: [Server]) {
        self.servers = servers
        getServersResult = .success(servers)
        if let firstServer = servers.first {
            selectedServerID = firstServer.id
            getSelectedServerResult = .success(firstServer)
        }
    }
    
    func setMockSelectedServer(_ server: Server?) {
        selectedServerID = server?.id
        getSelectedServerResult = .success(server)
    }
    
    func simulateKeychainError() {
        let error = MockKeychainError.readFailed
        getSelectedServerResult = .failure(error)
        getServersResult = .failure(error)
        addOrUpdateResult = .failure(error)
        removeResult = .failure(error)
        removeServersResult = .failure(error)
    }
    
    func resetMock() {
        autoRefreshInterval = 2.0
        servers.removeAll()
        selectedServerID = nil
        sortOption = .init(property: .dateAdded)
        filterOptions = .init()
        automaticallyLookForMagnetLinks = false
        
        getSelectedServerResult = .success(nil)
        getSelectedServerCallCount = 0
        getServersResult = .success([])
        getServersCallCount = 0
        addOrUpdateResult = .success(())
        addOrUpdateCallCount = 0
        addOrUpdateCalls.removeAll()
        removeResult = .success(())
        removeCallCount = 0
        removeCalls.removeAll()
        removeServersResult = .success(())
        removeServersCallCount = 0
        resetCallCount = 0
    }
}