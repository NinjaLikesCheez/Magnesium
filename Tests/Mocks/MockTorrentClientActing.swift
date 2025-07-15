import Foundation
import Combine
@testable import Magnesium

/// Mock implementation of TorrentClientActing for testing
class MockTorrentClientActing: TorrentClientActing {
    typealias AddLinkError = DefaultAddLinkError
    
    // MARK: - Mock Configuration
    
    var refreshResult: ([StandardTorrent], [StandardLabel]) = ([], [])
    var refreshError: Error?
    var refreshCallCount = 0
    var refreshDelay: TimeInterval = 0
    
    var refreshFilesResult: [StandardTorrentFile] = []
    var refreshFilesError: Error?
    var refreshFilesCallCount = 0
    
    var pathsResult: [String] = []
    var pathsError: Error?
    var pathsCallCount = 0
    
    var resumeResult: Result<Void, Error> = .success(())
    var resumeCallCount = 0
    var resumedTorrents: [StandardTorrent] = []
    
    var pauseResult: Result<Void, Error> = .success(())
    var pauseCallCount = 0
    var pausedTorrents: [StandardTorrent] = []
    
    var removeResult: Result<Void, Error> = .success(())
    var removeCallCount = 0
    var removedTorrents: [StandardTorrent] = []
    var removeWithDataFlags: [Bool] = []
    
    var verifyResult: Result<Void, Error> = .success(())
    var verifyCallCount = 0
    var verifiedTorrents: [StandardTorrent] = []
    
    var setLabelResult: Result<Void, Error> = .success(())
    var setLabelCallCount = 0
    var setLabelCalls: [(StandardLabel, [StandardTorrent])] = []
    
    var updateTrackersResult: Result<Void, Error> = .success(())
    var updateTrackersCallCount = 0
    var updateTrackersTorrents: [StandardTorrent] = []
    
    var moveDownloadFolderResult: Result<Void, Error> = .success(())
    var moveDownloadFolderCallCount = 0
    var moveDownloadFolderCalls: [(String, [StandardTorrent])] = []
    
    var addLinkResult: Result<Void, DefaultAddLinkError> = .success(())
    var addLinkCallCount = 0
    var addedLinks: [String] = []
    
    // MARK: - TorrentClientActing Implementation
    
    func refresh() async throws -> ([StandardTorrent], [StandardLabel]) {
        refreshCallCount += 1
        
        if refreshDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
        }
        
        if let error = refreshError {
            throw error
        }
        
        return refreshResult
    }
    
    func refreshFiles(_ torrent: StandardTorrent) async throws -> [StandardTorrentFile] {
        refreshFilesCallCount += 1
        
        if let error = refreshFilesError {
            throw error
        }
        
        return refreshFilesResult
    }
    
    func paths(_ torrent: StandardTorrent) async throws -> [String] {
        pathsCallCount += 1
        
        if let error = pathsError {
            throw error
        }
        
        return pathsResult
    }
    
    func pause(_ torrents: [StandardTorrent]) async throws {
        pauseCallCount += 1
        pausedTorrents.append(contentsOf: torrents)
        
        switch pauseResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func resume(_ torrents: [StandardTorrent]) async throws {
        resumeCallCount += 1
        resumedTorrents.append(contentsOf: torrents)
        
        switch resumeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws {
        removeCallCount += 1
        removedTorrents.append(contentsOf: torrents)
        removeWithDataFlags.append(removeData)
        
        switch removeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func verify(_ torrents: [StandardTorrent]) async throws {
        verifyCallCount += 1
        verifiedTorrents.append(contentsOf: torrents)
        
        switch verifyResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws {
        setLabelCallCount += 1
        setLabelCalls.append((label, torrents))
        
        switch setLabelResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func updateTrackers(_ torrents: [StandardTorrent]) async throws {
        updateTrackersCallCount += 1
        updateTrackersTorrents.append(contentsOf: torrents)
        
        switch updateTrackersResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws {
        moveDownloadFolderCallCount += 1
        moveDownloadFolderCalls.append((path, torrents))
        
        switch moveDownloadFolderResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func addLink(_ link: String) async throws(DefaultAddLinkError) {
        addLinkCallCount += 1
        addedLinks.append(link)
        
        switch addLinkResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        refreshResult = ([], [])
        refreshError = nil
        refreshCallCount = 0
        refreshDelay = 0
        
        refreshFilesResult = []
        refreshFilesError = nil
        refreshFilesCallCount = 0
        
        pathsResult = []
        pathsError = nil
        pathsCallCount = 0
        
        resumeResult = .success(())
        resumeCallCount = 0
        resumedTorrents.removeAll()
        
        pauseResult = .success(())
        pauseCallCount = 0
        pausedTorrents.removeAll()
        
        removeResult = .success(())
        removeCallCount = 0
        removedTorrents.removeAll()
        removeWithDataFlags.removeAll()
        
        verifyResult = .success(())
        verifyCallCount = 0
        verifiedTorrents.removeAll()
        
        setLabelResult = .success(())
        setLabelCallCount = 0
        setLabelCalls.removeAll()
        
        updateTrackersResult = .success(())
        updateTrackersCallCount = 0
        updateTrackersTorrents.removeAll()
        
        moveDownloadFolderResult = .success(())
        moveDownloadFolderCallCount = 0
        moveDownloadFolderCalls.removeAll()
        
        addLinkResult = .success(())
        addLinkCallCount = 0
        addedLinks.removeAll()
    }
    
    func simulateNetworkError() {
        refreshError = MockError.networkError
        refreshFilesError = MockError.networkError
        pathsError = MockError.networkError
        resumeResult = .failure(MockError.networkError)
        pauseResult = .failure(MockError.networkError)
        removeResult = .failure(MockError.networkError)
        verifyResult = .failure(MockError.networkError)
        setLabelResult = .failure(MockError.networkError)
        updateTrackersResult = .failure(MockError.networkError)
        moveDownloadFolderResult = .failure(MockError.networkError)
        addLinkResult = .failure(DefaultAddLinkError(title: "Network Error", message: "Network connection failed"))
    }
    
    func simulateAuthenticationError() {
        refreshError = MockError.authenticationError
        refreshFilesError = MockError.authenticationError
        pathsError = MockError.authenticationError
        resumeResult = .failure(MockError.authenticationError)
        pauseResult = .failure(MockError.authenticationError)
        removeResult = .failure(MockError.authenticationError)
        verifyResult = .failure(MockError.authenticationError)
        setLabelResult = .failure(MockError.authenticationError)
        updateTrackersResult = .failure(MockError.authenticationError)
        moveDownloadFolderResult = .failure(MockError.authenticationError)
        addLinkResult = .failure(DefaultAddLinkError(title: "Authentication Error", message: "Authentication failed"))
    }
}

// MARK: - Mock Errors

enum MockError: Error, LocalizedError {
    case networkError
    case authenticationError
    case invalidData
    case timeout
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .authenticationError:
            return "Authentication failed"
        case .invalidData:
            return "Invalid data received"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error with code \(code)"
        }
    }
}