import Combine
import CommonModels
import Deluge
@testable import Magnesium
import Preferences
import ViewModel
import XCTest

final class StandardTorrentDetailViewModelTests: XCTestCase {
    private var torrent: CurrentValueSubject<MockTorrent, Never>!
    private var labels: CurrentValueSubject<[MockLabel], Never>!
    private var implementation: MockImplementation!
    private var viewModel: StandardTorrentDetailViewModel<MockImplementation>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        torrent = CurrentValueSubject(MockTorrent(name: "Mock", downloadPath: "/downloads"))
        labels = CurrentValueSubject([MockLabel(), MockLabel(name: "label1"), MockLabel(name: "label2")])
        implementation = MockImplementation()
        viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels
        )
    }

    private func getAlert(actions: @escaping () -> Void) throws -> Alert {
        let event = try viewModel.events.first().wait(executing: actions).value()
        return try unpack(case: type(of: event).alert, from: event)
    }

    // MARK: Auto Refresh

    func test_autoRefresh_whenNotAppeared_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenAppeared_shouldFire() {
        preferences[.autoRefreshInterval] = 1
        viewModel.receive(.appear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenDisappeared_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        viewModel.receive(.appear)
        viewModel.receive(.disappear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.updateFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        viewModel.receive(.appear)
        preferences[.autoRefreshInterval] = 0
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
        viewModel.receive(.refresh)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_refresh_whenFails_shouldShowError() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = try getAlert {
            self.viewModel.receive(.refresh)
        }
        XCTAssertEqual(alert.title, "Update Failed")
    }

    func test_refresh_isRefreshing_shouldEmitTrueThenFalse() {
        let values = viewModel.view.isRefreshing.dropFirst().wait {
            self.viewModel.receive(.refresh)
        }
        XCTAssertEqual(values, [true, false])
    }

    // MARK: moreOptions

    private func getActivities(actions: @escaping () -> Void) throws -> [Activity] {
        let event = try viewModel.events.first().wait(executing: actions).value()
        return try unpack(case: type(of: event).activities, from: event).0
    }

    func test_moreOptions_shouldEmitExpectedActivities() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    func test_moreOptionsSelected_withNoLabels_shouldEmitExpectedActivities() throws {
        labels.send([])
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    // MARK: moreOptions - Set Label

    func test_setLabelActivity_shouldEmitSelectionAlert() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        XCTAssertEqual(alert.actions.map(\.title), ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_whenOptionSelected_shouldCallImplementationSetLabelAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        alert.actions.first { $0.title == "label1" }?.handler?()
        XCTAssertEqual(implementation.setLabelCallCount, 1)
        XCTAssertEqual(implementation.setLabelParamLabel[0].name, "label1")
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_setLabelActivity_whenOptionSelected_andFails_shouldEmitAlert() throws {
        implementation.setLabelResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let optionsAlert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "label1" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Set Label")
    }

    // MARK: moreOptions - Verify Files

    func test_verifyFilesActivity_shouldCallImplementationVerifyFilesAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Verify Files" }?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_verifyFilesActivity_whenFails_shouldEmitAlert() throws {
        implementation.verifyResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Verify Files" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Verify Files")
    }

    // MARK: moreOptions - Move Download Folder

    func test_moveDownloadFolderActivity_shouldEmitMoveDownloadFolderEvent() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (path, _) = try unpack(case: TorrentDetailViewModelEvent.moveDownloadFolder, from: event)
        XCTAssertEqual(path, "/downloads")
    }

    // swiftlint:disable:next line_length
    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_shouldCallImplementationMoveDownloadFolderAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (_, subject) = try unpack(case: TorrentDetailViewModelEvent.moveDownloadFolder, from: event)
        subject.send("/new")
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath, ["/new"])
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andFails_shouldEmitAlert() throws {
        implementation.moveDownloadFolderResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (_, subject) = try unpack(case: TorrentDetailViewModelEvent.moveDownloadFolder, from: event)
        let alert = try getAlert {
            subject.send("/new")
        }
        XCTAssertEqual(alert.title, "Failed to Move Download Folder")
    }

    // MARK: moreOptions - Update Trackers

    func test_updateTrackersActivity_shouldCallImplementationUpdateTrackersAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Update Trackers" }?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_updateTrackersActivity_whenFails_shouldEmitAlert() throws {
        implementation.updateTrackersResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.receive(.moreOptions(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Update Trackers")
    }

    // MARK: pause

    func test_pause_shouldCallImplementationPauseAndRefresh() {
        viewModel.receive(.pause)
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_pause_whenFails_shouldEmitAlert() throws {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = try getAlert {
            self.viewModel.receive(.pause)
        }
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    // MARK: resume

    func test_resume_shouldCallImplementationPauseAndRefresh() {
        viewModel.receive(.resume)
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_resume_whenFails_shouldEmitAlert() throws {
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = try getAlert {
            self.viewModel.receive(.resume)
        }
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    // MARK: remove

    func test_removeSelected_shouldEmitAlert() throws {
        let alert = try getAlert {
            self.viewModel.receive(.remove(source: .view(UIView(), rect: .zero)))
        }
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_whenKeepDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.receive(.remove(source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
    }

    func test_removeSelected_whenKeepDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = try getAlert {
            self.viewModel.receive(.remove(source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenRemoveDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.receive(.remove(source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
    }

    func test_removeSelected_whenRemoveDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = try getAlert {
            self.viewModel.receive(.remove(source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    // MARK: - State

    // MARK: sections

    func test_sections_shouldHaveHeader() throws {
        let sections = try viewModel.view.sections.first().wait().value()
        XCTAssertEqual(sections.first?.type, .header)
        XCTAssertEqual(sections.first?.items.count, 1)
    }

    // swiftlint:disable:next large_tuple
    private func getInfoRows(in section: TorrentDetailSection) throws -> [(String, String, String?)] {
        XCTAssertEqual(section.type, .info)
        return try section.items.compactMap { item -> (String, String, String?)? in
            switch item {
            case let .info(item):
                return (
                    item.name,
                    try item.value.first().wait().value(),
                    try item.expandedValue?.first().wait().value()
                )
            default:
                XCTFail("Unexpected item")
                return nil
            }
        }
    }

    func test_sections_shouldHaveInfoRows() throws {
        // swiftformat:disable all
        // swiftlint:disable comma
        let expected: [(String, String, String?)] = [
            ("Size",            "0 KB",         nil),
            ("Download Speed",  "0 KB/s",       nil),
            ("Upload Speed",    "0 KB/s",       nil),
            ("Downloaded",      "0 KB",         nil),
            ("Uploaded",        "0 KB",         nil),
            ("ETA",             "∞",            nil),
            ("Ratio",           "∞",            nil),
            ("Peers",           "0 (0)",        nil),
            ("Seeds",           "0 (0)",        nil),
            ("Download Folder", "downloads",    "/downloads"),
        ]
        // swiftlint:enable comma
        // swiftformat:enable all
        let section = try viewModel.view.sections.first().wait().value()[1]
        let rows = try getInfoRows(in: section)
        XCTAssertEqual(rows.count, expected.count, String(describing: rows))
        for (row, expected) in zip(rows, expected) {
            XCTAssertEqual(row.0, expected.0)
            XCTAssertEqual(row.1, expected.1, row.0)
            XCTAssertEqual(row.2, expected.2, row.0)
        }
    }

    func test_sections_shouldHaveTrackers() throws {
        let trackers = ["udp://tracker.example.com:9000", "http://tracker.example.com:9000/announce"]
        torrent.send(MockTorrent(trackerStrings: trackers))

        let section = try viewModel.view.sections.first().wait().value()[2]
        XCTAssertEqual(section.type, .trackers)
        let unpacked = try section.items.map { try unpack(case: TorrentDetailItem.tracker, from: $0) }
        XCTAssertEqual(unpacked, trackers)
    }

    func test_sections_files_shouldBeSorted() throws {
        let section = try viewModel.view.sections.first().wait().value()[2]
        XCTAssertEqual(section.type, .files)
        let files = try section.items.map {
            try unpack(case: TorrentDetailItem.file, from: $0).name.first().wait().value()
        }
        XCTAssertEqual(files, ["file.r00", "file.r01", "file.rar"])
    }

    // MARK: eta

    func test_eta_whenZero_shouldFormatProperly() throws {
        let sections = try viewModel.view.sections.first().wait().value()
        let eta = try getInfoRows(in: sections[1]).first { $0.0 == "ETA" }?.1
        XCTAssertEqual(eta, "∞")
    }

    // MARK: ratio

    func test_ratio_whenInfinite_shouldFormatProperly() throws {
        torrent.send(MockTorrent(uploaded: 1))
        XCTAssertTrue(torrent.value.ratio.isInfinite)
        let sections = try viewModel.view.sections.first().wait().value()
        let eta = try getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }?.1
        XCTAssertEqual(eta, "∞")
    }

    func test_ratio_whenNaN_shouldFormatProperly() throws {
        XCTAssertTrue(torrent.value.ratio.isNaN)
        let sections = try viewModel.view.sections.first().wait().value()
        let eta = try getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }?.1
        XCTAssertEqual(eta, "∞")
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
