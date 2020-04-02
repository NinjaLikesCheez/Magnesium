import Combine
@testable import Magnesium

extension StandardTorrentDetailImplementation {
    static func mock(_ impl: MockStandardTorrentDetailImplementation) -> StandardTorrentDetailImplementation {
        .init(
            refresh: impl.refresh,
            refreshFiles: impl.refreshFiles(torrent:),
            pause: impl.pause(torrent:),
            resume: impl.resume(torrent:),
            remove: impl.remove(torrent:removeData:),
            verify: impl.verify(torrent:),
            setLabel: impl.setLabel(label:for:),
            updateTrackers: impl.updateTrackers(torrent:),
            moveDownloadFolder: impl.moveDownloadFolder(path:torrent:),
            setPriority: impl.setPriority(torrent:files:priorities:)
        )
    }
}

final class MockStandardTorrentDetailImplementation {
    private(set) var refreshCallCount = 0
    var refreshResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func refresh() -> AnyPublisher<Void, Error> {
        refreshCallCount += 1
        return refreshResult
    }

    private(set) var refreshFilesCallCount = 0
    private(set) var refreshFilesParamTorrent = [StandardTorrent]()
    var refreshFilesResult = Just([StandardTorrentFile]()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func refreshFiles(torrent: StandardTorrent) -> AnyPublisher<[StandardTorrentFile], Error> {
        refreshFilesCallCount += 1
        refreshFilesParamTorrent.append(torrent)
        return refreshFilesResult
    }

    private(set) var pauseCallCount = 0
    private(set) var pauseParamTorrent = [StandardTorrent]()
    var pauseResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func pause(torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        pauseCallCount += 1
        pauseParamTorrent.append(torrent)
        return pauseResult
    }

    private(set) var resumeCallCount = 0
    private(set) var resumeParamTorrent = [StandardTorrent]()
    var resumeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func resume(torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        resumeCallCount += 1
        resumeParamTorrent.append(torrent)
        return resumeResult
    }

    private(set) var removeCallCount = 0
    private(set) var removeParamTorrent = [StandardTorrent]()
    private(set) var removeParamRemoveData = [Bool]()
    var removeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func remove(torrent: StandardTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        removeCallCount += 1
        removeParamTorrent.append(torrent)
        removeParamRemoveData.append(removeData)
        return removeResult
    }

    private(set) var verifyCallCount = 0
    private(set) var verifyParamTorrent = [StandardTorrent]()
    var verifyResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func verify(torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        verifyCallCount += 1
        verifyParamTorrent.append(torrent)
        return verifyResult
    }

    private(set) var setLabelCallCount = 0
    private(set) var setLabelParamLabel = [StandardLabel]()
    private(set) var setLabelParamTorrent = [StandardTorrent]()
    var setLabelResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func setLabel(label: StandardLabel, for torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        setLabelCallCount += 1
        setLabelParamLabel.append(label)
        setLabelParamTorrent.append(torrent)
        return setLabelResult
    }

    private(set) var updateTrackersCallCount = 0
    private(set) var updateTrackersParamTorrent = [StandardTorrent]()
    var updateTrackersResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func updateTrackers(torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        updateTrackersCallCount += 1
        updateTrackersParamTorrent.append(torrent)
        return updateTrackersResult
    }

    private(set) var moveDownloadFolderCallCount = 0
    private(set) var moveDownloadFolderParamPath = [String]()
    private(set) var moveDownloadFolderParamTorrent = [StandardTorrent]()
    var moveDownloadFolderResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func moveDownloadFolder(path: String, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        moveDownloadFolderCallCount += 1
        moveDownloadFolderParamPath.append(path)
        moveDownloadFolderParamTorrent.append(torrent)
        return moveDownloadFolderResult
    }

    private(set) var setPriorityCallCount = 0
    private(set) var setPriorityParamTorrent = [StandardTorrent]()
    private(set) var setPriorityParamFiles = [[StandardTorrentFile]]()
    private(set) var setPriorityParamPriorities = [[StandardTorrentFile: TorrentPriority]]()
    var setPriorityResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func setPriority(
        torrent: StandardTorrent,
        files: [StandardTorrentFile],
        priorities: [StandardTorrentFile: TorrentPriority]
    ) -> AnyPublisher<Void, Error> {
        setPriorityCallCount += 1
        setPriorityParamTorrent.append(torrent)
        setPriorityParamFiles.append(files)
        setPriorityParamPriorities.append(priorities)
        return setPriorityResult
    }
}
