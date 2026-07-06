import Foundation
import TorrentCore

@testable import TorrentSession

/// Mock implementation of TorrentClient for testing
final class MockTorrentClient: TorrentClient {
	// MARK: - Mock Configuration

	var refreshResult: ([StandardTorrent], [StandardLabel]) = ([], [])
	var refreshError: TorrentClientError?
	var refreshCallCount = 0
	var refreshDelay: TimeInterval = 0

	var refreshFilesResult: [StandardTorrentFile] = []
	var refreshFilesError: TorrentClientError?
	var refreshFilesCallCount = 0

	var pathsResult: [String] = []
	var pathsError: TorrentClientError?
	var pathsCallCount = 0

	var resumeResult: Result<Void, TorrentClientError> = .success(())
	var resumeCallCount = 0
	var resumedTorrents: [StandardTorrent] = []

	var pauseResult: Result<Void, TorrentClientError> = .success(())
	var pauseCallCount = 0
	var pausedTorrents: [StandardTorrent] = []

	var removeResult: Result<Void, TorrentClientError> = .success(())
	var removeCallCount = 0
	var removedTorrents: [StandardTorrent] = []
	var removeWithDataFlags: [Bool] = []

	var verifyResult: Result<Void, TorrentClientError> = .success(())
	var verifyCallCount = 0
	var verifiedTorrents: [StandardTorrent] = []

	var setLabelResult: Result<Void, TorrentClientError> = .success(())
	var setLabelCallCount = 0
	var setLabelCalls: [(StandardLabel, [StandardTorrent])] = []

	var updateTrackersResult: Result<Void, TorrentClientError> = .success(())
	var updateTrackersCallCount = 0
	var updateTrackersTorrents: [StandardTorrent] = []

	var moveDownloadFolderResult: Result<Void, TorrentClientError> = .success(())
	var moveDownloadFolderCallCount = 0
	var moveDownloadFolderCalls: [(String, [StandardTorrent])] = []

	var addLinkResult: Result<Void, TorrentClientError> = .success(())
	var addLinkCallCount = 0
	var addedLinks: [String] = []

	// MARK: - TorrentClient Implementation

	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) {
		refreshCallCount += 1

		if refreshDelay > 0 {
			try? await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
		}

		if let error = refreshError {
			throw error
		}

		return refreshResult
	}

	func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] {
		refreshFilesCallCount += 1

		if let error = refreshFilesError {
			throw error
		}

		return refreshFilesResult
	}

	func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String] {
		pathsCallCount += 1

		if let error = pathsError {
			throw error
		}

		return pathsResult
	}

	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		pauseCallCount += 1
		pausedTorrents.append(contentsOf: torrents)

		switch pauseResult {
		case .success:
			return
		case .failure(let error):
			throw error
		}
	}

	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		resumeCallCount += 1
		resumedTorrents.append(contentsOf: torrents)

		switch resumeResult {
		case .success:
			return
		case .failure(let error):
			throw error
		}
	}

	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError) {
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

	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		verifyCallCount += 1
		verifiedTorrents.append(contentsOf: torrents)

		switch verifyResult {
		case .success:
			return
		case .failure(let error):
			throw error
		}
	}

	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		setLabelCallCount += 1
		setLabelCalls.append((label, torrents))

		switch setLabelResult {
		case .success:
			return
		case .failure(let error):
			throw error
		}
	}

	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		updateTrackersCallCount += 1
		updateTrackersTorrents.append(contentsOf: torrents)

		switch updateTrackersResult {
		case .success:
			return
		case .failure(let error):
			throw error
		}
	}

	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		moveDownloadFolderCallCount += 1
		moveDownloadFolderCalls.append((path, torrents))

		switch moveDownloadFolderResult {
		case .success:
			return
		case .failure(let error):
			throw error
		}
	}

	func addLink(_ link: String) async throws(TorrentClientError) {
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
		let error = URLError(.notConnectedToInternet)
		refreshError = TorrentClientError.deluge(.request(.urlError(error)))
		refreshFilesError = TorrentClientError.deluge(.request(.urlError(error)))
		pathsError = TorrentClientError.deluge(.request(.urlError(error)))
		resumeResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		pauseResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		removeResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		verifyResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		setLabelResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		updateTrackersResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		moveDownloadFolderResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
		addLinkResult = .failure(TorrentClientError.deluge(.request(.urlError(error))))
	}

	func simulateAuthenticationError() {
		refreshError = TorrentClientError.deluge(.response(.unauthenticated))
		refreshFilesError = TorrentClientError.deluge(.response(.unauthenticated))
		pathsError = TorrentClientError.deluge(.response(.unauthenticated))
		resumeResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		pauseResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		removeResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		verifyResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		setLabelResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		updateTrackersResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		moveDownloadFolderResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))
		addLinkResult = .failure(TorrentClientError.invalidLinkAdded)
	}
}
