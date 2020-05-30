import Combine
@testable import Magnesium
import ViewModel
import XCTest

extension StandardTorrentListImplementation {
    static func mock(_ impl: MockStandardTorrentListImplementation) -> StandardTorrentListImplementation {
        .init(
            updated: impl.updatedSubject.eraseToAnyPublisher(),
            refresh: impl.refresh,
            detailViewModel: impl.detailViewModel(torrentSubject:labelsSubject:),
            addLink: impl.addLink(url:),
            pause: impl.pause(torrents:),
            resume: impl.resume(torrents:),
            remove: impl.remove(torrents:removeData:),
            verify: impl.verify(_:),
            setLabel: impl.setLabel(label:torrents:),
            updateTrackers: impl.updateTrackers(torrents:),
            moveDownloadFolder: impl.moveDownloadFolder(path:torrents:)
        )
    }
}

final class MockStandardTorrentListImplementation {
    typealias AddLinkError = StandardTorrentListImplementation.AddLinkError

    let updatedSubject = PassthroughSubject<([StandardTorrent], [StandardLabel]), Never>()

    private(set) var refreshCallCount = 0
    var refreshResult = Just((
        [
            StandardTorrent.mock(dateAdded: Date(), name: "Mock"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -1), name: "Mock 2"),
        ],
        [
            StandardLabel.mock(name: ""),
            StandardLabel.mock(name: "label1"),
            StandardLabel.mock(name: "label2"),
        ]
    )).setFailureType(to: Error.self).eraseToAnyPublisher()
    func refresh() -> AnyPublisher<([StandardTorrent], [StandardLabel]), Error> {
        refreshCallCount += 1
        return refreshResult
    }

    private(set) var detailViewModelCallCount = 0
    private(set) var detailViewModelParamTorrent = [CurrentValueSubject<StandardTorrent, Never>]()
    private(set) var detailViewModelParamLabels = [CurrentValueSubject<[StandardLabel], Never>]()
    var detailViewModelResult = AnyViewModel(MockDetailViewModel())
    func detailViewModel(
        torrentSubject: CurrentValueSubject<StandardTorrent, Never>,
        labelsSubject: CurrentValueSubject<[StandardLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        detailViewModelCallCount += 1
        detailViewModelParamTorrent.append(torrentSubject)
        detailViewModelParamLabels.append(labelsSubject)
        return detailViewModelResult
    }

    private(set) var addLinkCallCount = 0
    private(set) var addLinkParamURL = [String]()
    var addLinkResult = Empty<Void, AddLinkError>(completeImmediately: true).eraseToAnyPublisher()
    func addLink(url: String) -> AnyPublisher<Void, AddLinkError> {
        addLinkCallCount += 1
        addLinkParamURL.append(url)
        return addLinkResult
    }

    private(set) var pauseCallCount = 0
    private(set) var pauseParamTorrents = [[StandardTorrent]]()
    var pauseResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func pause(torrents: [StandardTorrent]) -> AnyPublisher<Void, Error> {
        pauseCallCount += 1
        pauseParamTorrents.append(torrents)
        return pauseResult
    }

    private(set) var resumeCallCount = 0
    private(set) var resumeParamTorrents = [[StandardTorrent]]()
    var resumeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func resume(torrents: [StandardTorrent]) -> AnyPublisher<Void, Error> {
        resumeCallCount += 1
        resumeParamTorrents.append(torrents)
        return resumeResult
    }

    private(set) var removeCallCount = 0
    private(set) var removeParamTorrents = [[StandardTorrent]]()
    private(set) var removeParamRemoveData = [Bool]()
    var removeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func remove(torrents: [StandardTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        removeCallCount += 1
        removeParamTorrents.append(torrents)
        removeParamRemoveData.append(removeData)
        return removeResult
    }

    private(set) var verifyCallCount = 0
    private(set) var verifyParamTorrents = [[StandardTorrent]]()
    var verifyResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func verify(_ torrents: [StandardTorrent]) -> AnyPublisher<Void, Error> {
        verifyCallCount += 1
        verifyParamTorrents.append(torrents)
        return verifyResult
    }

    private(set) var setLabelCallCount = 0
    private(set) var setLabelParamLabel = [StandardLabel]()
    private(set) var setLabelParamTorrents = [[StandardTorrent]]()
    var setLabelResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func setLabel(label: StandardLabel, torrents: [StandardTorrent]) -> AnyPublisher<Void, Error> {
        setLabelCallCount += 1
        setLabelParamLabel.append(label)
        setLabelParamTorrents.append(torrents)
        return setLabelResult
    }

    private(set) var updateTrackersCallCount = 0
    private(set) var updateTrackersParamTorrents = [[StandardTorrent]]()
    var updateTrackersResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func updateTrackers(torrents: [StandardTorrent]) -> AnyPublisher<Void, Error> {
        updateTrackersCallCount += 1
        updateTrackersParamTorrents.append(torrents)
        return updateTrackersResult
    }

    private(set) var moveDownloadFolderCallCount = 0
    private(set) var moveDownloadFolderParamPath = [String]()
    private(set) var moveDownloadFolderParamTorrents = [[StandardTorrent]]()
    var moveDownloadFolderResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func moveDownloadFolder(path: String, torrents: [StandardTorrent]) -> AnyPublisher<Void, Error> {
        moveDownloadFolderCallCount += 1
        moveDownloadFolderParamTorrents.append(torrents)
        moveDownloadFolderParamPath.append(path)
        return moveDownloadFolderResult
    }
}

private final class MockDetailViewModel: ViewModel {
    let values = TorrentDetailViewValues.mock()
    let eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()
    func send(_ event: TorrentDetailViewEvent) {}
}
