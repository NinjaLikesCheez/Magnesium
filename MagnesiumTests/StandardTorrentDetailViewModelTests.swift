import Combine
@testable import Magnesium
import ViewModel
import XCTest

final class StandardTorrentDetailViewModelTests: XCTestCase {
    private var torrent: CurrentValueSubject<MockTorrent, Never>!
    private var labels: CurrentValueSubject<[MockLabel], Never>!
    private var preferences: MockPreferences!
    private var implementation: MockImplementation!
    private var viewModel: StandardTorrentDetailViewModel<MockImplementation>!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        torrent = CurrentValueSubject(MockTorrent(name: "Mock", downloadPath: "/downloads"))
        labels = CurrentValueSubject([MockLabel(), MockLabel(name: "label1"), MockLabel(name: "label2")])
        preferences = MockPreferences()
        implementation = MockImplementation()
        viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels,
            preferences: preferences
        )
    }

    private func getAlert(actions: () -> Void) -> Alert? {
        var event: TorrentDetailEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        actions()
        guard case let .alert(alert, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return nil
        }
        return alert
    }

    // MARK: Auto Refresh

    func test_autoRefresh_whenNotAppeared_shouldNotFire() {
        preferences.set(1, for: .autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenAppeared_shouldFire() {
        preferences.set(1, for: .autoRefreshInterval)
        viewModel.handle(.appear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenDisappeared_shouldNotFire() {
        preferences.set(1, for: .autoRefreshInterval)
        viewModel.handle(.appear)
        viewModel.handle(.disappear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        preferences.set(1, for: .autoRefreshInterval)
        viewModel.handle(.appear)
        preferences.set(0, for: .autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    // MARK: - Handle TorrentDetailViewEvent

    // MARK: refresh

    func test_refresh_shouldCallImplementationRefresh() {
        viewModel.handle(.refresh)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_refresh_whenFails_shouldShowError() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.handle(.refresh)
        }!
        XCTAssertEqual(alert.title, "Update Failed")
    }

    func test_refresh_isRefreshing_shouldEmitTrueThenFalse() {
        var values = [Bool]()
        viewModel.state.isRefreshing.dropFirst().sink { values.append($0) }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(values, [true, false])
    }

    // MARK: moreOptions

    private func getActivities(actions: () -> Void) -> [Activity]? {
        var event: TorrentDetailEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        actions()
        guard case let .activities(activities, _, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return nil
        }
        return activities
    }

    func test_moreOptions_shouldEmitExpectedActivities() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map { $0.title }, expected)
    }

    func test_moreOptionsSelected_withNoLabels_shouldEmitExpectedActivities() {
        labels.send([])
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let expected = ["Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map { $0.title }, expected)
    }

    // MARK: moreOptions - Set Label

    func test_setLabelActivity_shouldEmitSelectionAlert() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        XCTAssertEqual(alert.actions.map { $0.title }, ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_whenOptionSelected_shouldCallImplementationSetLabelAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        alert.actions.first { $0.title == "label1" }?.handler?()
        XCTAssertEqual(implementation.setLabelCallCount, 1)
        XCTAssertEqual(implementation.setLabelParamLabel[0].name, "label1")
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_setLabelActivity_whenOptionSelected_andFails_shouldEmitAlert() {
        implementation.setLabelResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let optionsAlert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        let errorAlert = getAlert {
            optionsAlert.actions.first { $0.title == "label1" }?.handler?()
        }!
        XCTAssertEqual(errorAlert.title, "Failed to Set Label")
    }

    // MARK: moreOptions - Verify Files

    func test_verifyFilesActivity_shouldCallImplementationVerifyFilesAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        activities.first { $0.title == "Verify Files" }?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_verifyFilesActivity_whenFails_shouldEmitAlert() {
        implementation.verifyResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Verify Files" }?.handler()
        }!
        XCTAssertEqual(alert.title, "Failed to Verify Files")
    }

    // MARK: moreOptions - Move Download Folder

    func test_moveDownloadFolderActivity_shouldEmitMoveDownloadFolderEvent() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentDetailEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case let .moveDownloadFolder(path, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(path, "/downloads")
    }

    // swiftlint:disable:next line_length
    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_shouldCallImplementationMoveDownloadFolderAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentDetailEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case let .moveDownloadFolder(_, subject) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        subject.send("/new")
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath[0], "/new")
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andFails_shouldEmitAlert() {
        implementation.moveDownloadFolderResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentDetailEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case let .moveDownloadFolder(_, subject) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        let alert = getAlert {
            subject.send("/new")
        }!
        XCTAssertEqual(alert.title, "Failed to Move Download Folder")
    }

    // MARK: moreOptions - Update Trackers

    func test_updateTrackersActivity_shouldCallImplementationUpdateTrackersAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        activities.first { $0.title == "Update Trackers" }?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_updateTrackersActivity_whenFails_shouldEmitAlert() {
        implementation.updateTrackersResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }!
        XCTAssertEqual(alert.title, "Failed to Update Trackers")
    }

    // MARK: pause

    func test_pause_shouldCallImplementationPauseAndRefresh() {
        viewModel.handle(.pause)
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_pause_whenFails_shouldEmitAlert() {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.handle(.pause)
        }!
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    // MARK: resume

    func test_resume_shouldCallImplementationPauseAndRefresh() {
        viewModel.handle(.resume)
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_resume_whenFails_shouldEmitAlert() {
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.handle(.resume)
        }!
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    // MARK: remove

    func test_removeSelected_shouldEmitAlert() {
        let alert = getAlert {
            viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        }!
        XCTAssertEqual(alert.actions.map { $0.title }, ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_whenKeepDataSelected_shouldCallImplementationRemoveAndRefresh() {
        let alert = getAlert {
            viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        }!
        alert.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
    }

    func test_removeSelected_whenKeepDataSelected_andFails_shouldEmitAlert() {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = getAlert {
            viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        }!

        let errorAlert = getAlert {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }!
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenRemoveDataSelected_shouldCallImplementationRemoveAndRefresh() {
        let alert = getAlert {
            viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        }!
        alert.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
    }

    func test_removeSelected_whenRemoveDataSelected_andFails_shouldEmitAlert() {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = getAlert {
            viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        }!

        let errorAlert = getAlert {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }!
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    // MARK: - State

    // MARK: sections

    func test_sections_shouldHaveHeader() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[0]
            XCTAssertEqual(section.type, .header)
            XCTAssertEqual(section.items.count, 1)
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    private func getInfoRows(in section: TorrentDetailSection) -> [(String, String)] {
        XCTAssertEqual(section.type, .info)
        return section.items.compactMap { item -> (String, String)? in
            switch item {
            case let .info(item):
                let expectation = self.expectation(description: "Value received")
                var value: String!
                item.value.first().sink {
                    value = $0
                    expectation.fulfill()
                }.store(in: &self.observers)
                self.wait(for: [expectation], timeout: 0)
                return (item.name, value)
            default:
                XCTFail("Unexpected item")
                return nil
            }
        }
    }

    func test_sections_shouldHaveInfoRows() {
        let expected: [(String, String)] = [
            ("Size", "0 KB"),
            ("Download Speed", "0 KB/s"),
            ("Upload Speed", "0 KB/s"),
            ("Downloaded", "0 KB"),
            ("Uploaded", "0 KB"),
            ("ETA", "∞"),
            ("Ratio", "∞"),
            ("Peers", "0 (0)"),
            ("Seeds", "0 (0)"),
        ]

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let rows = self.getInfoRows(in: sections[1])
            for (row, expected) in zip(rows, expected) {
                XCTAssertEqual(row.0, expected.0)
                XCTAssertEqual(row.1, expected.1, row.0)
            }
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_sections_shouldHaveTrackers() {
        let trackers = ["udp://tracker.example.com:9000", "http://tracker.example.com:9000/announce"]
        torrent.send(MockTorrent(trackerStrings: trackers))

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[2]
            XCTAssertEqual(section.type, .trackers)

            let inner = section.items.compactMap { item -> String? in
                switch item {
                case let .tracker(tracker):
                    return tracker
                default:
                    XCTFail("Unexpected item")
                    return nil
                }
            }

            XCTAssertEqual(inner, trackers)
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_sections_files_shouldBeSorted() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[2]
            XCTAssertEqual(section.type, .files)

            let files = section.items.compactMap { item -> String? in
                switch item {
                case let .file(item):
                    var value: String?
                    item.name.sink { value = $0 }.store(in: &self.observers)
                    return value
                default:
                    XCTFail("Unexpected item")
                    return nil
                }
            }
            XCTAssertEqual(files, ["file.r00", "file.r01", "file.rar"])
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    // MARK: eta

    func test_eta_whenZero_shouldFormatProperly() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "ETA" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    // MARK: ratio

    func test_ratio_whenInfinite_shouldFormatProperly() {
        torrent.send(MockTorrent(uploaded: 1))
        XCTAssertTrue(torrent.value.ratio.isInfinite)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        XCTAssertTrue(torrent.value.ratio.isNaN)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }
}

private final class MockImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = MockTorrent
    typealias Label = MockLabel
    typealias File = MockTorrentFile

    private(set) var refreshCallCount = 0
    var refreshResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func refresh() -> AnyPublisher<Void, Error> {
        refreshCallCount += 1
        return refreshResult
    }

    private(set) var updateFilesCallCount = 0
    private(set) var updateFilesParamTorrent = [MockTorrent]()
    var updateFilesResult = Just([
        MockTorrentFile(index: 0, name: "file.rar"),
        MockTorrentFile(index: 1, name: "file.r01"),
        MockTorrentFile(index: 2, name: "file.r00"),
    ]).setFailureType(to: Error.self).eraseToAnyPublisher()
    func updateFiles(_ torrent: MockTorrent) -> AnyPublisher<[MockTorrentFile], Error> {
        updateFilesCallCount += 1
        updateFilesParamTorrent.append(torrent)
        return updateFilesResult
    }

    private(set) var pauseCallCount = 0
    private(set) var pauseParamTorrent = [MockTorrent]()
    var pauseResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func pause(_ torrent: MockTorrent) -> AnyPublisher<Void, Error> {
        pauseCallCount += 1
        pauseParamTorrent.append(torrent)
        return pauseResult
    }

    private(set) var resumeCallCount = 0
    private(set) var resumeParamTorrent = [MockTorrent]()
    var resumeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func resume(_ torrent: MockTorrent) -> AnyPublisher<Void, Error> {
        resumeCallCount += 1
        resumeParamTorrent.append(torrent)
        return resumeResult
    }

    private(set) var removeCallCount = 0
    private(set) var removeParamTorrent = [MockTorrent]()
    private(set) var removeParamRemoveData = [Bool]()
    var removeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func remove(_ torrent: MockTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        removeCallCount += 1
        removeParamTorrent.append(torrent)
        removeParamRemoveData.append(removeData)
        return removeResult
    }

    private(set) var verifyCallCount = 0
    private(set) var verifyParamTorrent = [MockTorrent]()
    var verifyResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func verify(_ torrent: MockTorrent) -> AnyPublisher<Void, Error> {
        verifyCallCount += 1
        verifyParamTorrent.append(torrent)
        return verifyResult
    }

    private(set) var setLabelCallCount = 0
    private(set) var setLabelParamLabel = [MockLabel]()
    private(set) var setLabelParamTorrent = [MockTorrent]()
    var setLabelResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func setLabel(_ label: MockLabel, for torrent: MockTorrent) -> AnyPublisher<Void, Error> {
        setLabelCallCount += 1
        setLabelParamLabel.append(label)
        setLabelParamTorrent.append(torrent)
        return setLabelResult
    }

    private(set) var updateTrackersCallCount = 0
    private(set) var updateTrackersParamTorrent = [MockTorrent]()
    var updateTrackersResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func updateTrackers(for torrent: MockTorrent) -> AnyPublisher<Void, Error> {
        updateTrackersCallCount += 1
        updateTrackersParamTorrent.append(torrent)
        return updateTrackersResult
    }

    private(set) var moveDownloadFolderCallCount = 0
    private(set) var moveDownloadFolderParamTorrent = [MockTorrent]()
    private(set) var moveDownloadFolderParamPath = [String]()
    var moveDownloadFolderResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func moveDownloadFolder(for torrent: MockTorrent, to path: String) -> AnyPublisher<Void, Error> {
        moveDownloadFolderCallCount += 1
        moveDownloadFolderParamTorrent.append(torrent)
        moveDownloadFolderParamPath.append(path)
        return moveDownloadFolderResult
    }
}
