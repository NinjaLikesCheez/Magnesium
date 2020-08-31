import Combine
import CommonModels
import Deluge
@testable import Magnesium
import Preferences
import SnapshotTesting
import ViewModel
import XCTest

final class StandardTorrentDetailViewModelTests: TestCase {
    private var torrentSubject: CurrentValueSubject<StandardTorrent, Never>!
    private var labelsSubject: CurrentValueSubject<[StandardLabel], Never>!
    private var implementation: MockStandardTorrentDetailImplementation!
    private var viewModel: StandardTorrentDetailViewModel!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        torrentSubject = CurrentValueSubject(.mock(downloadPath: "/downloads", name: "Mock"))
        labelsSubject = CurrentValueSubject([.mock(), .mock(name: "label1"), .mock(name: "label2")])
        implementation = MockStandardTorrentDetailImplementation()
        implementation.refreshFilesResult = Just([
            StandardTorrentFile.mock(index: 0, name: "file.rar"),
            StandardTorrentFile.mock(index: 1, name: "file.r01"),
            StandardTorrentFile.mock(index: 2, name: "file.r00"),
        ]).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel = StandardTorrentDetailViewModel(
            implementation: .mock(implementation),
            torrentSubject: torrentSubject,
            labelsSubject: labelsSubject
        )
    }

    private func getAlert(actions: @escaping () -> Void) throws -> Alert {
        let event = try viewModel.eventPublisher.first().wait(executing: actions).singleValue()
        return try extract(case: type(of: event).alert, from: event)
    }

    // MARK: Auto Refresh

    func test_autoRefresh_whenNotAppeared_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenAppeared_shouldFire() {
        preferences[.autoRefreshInterval] = 1
        viewModel.send(.appeared)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshFilesCallCount, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenDisappeared_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        viewModel.send(.appeared)
        viewModel.send(.disappeared)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        viewModel.send(.appeared)
        preferences[.autoRefreshInterval] = 0
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshFilesCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    // MARK: - Handle TorrentDetailViewEvent

    // MARK: refresh

    func test_refresh_shouldCallImplementationRefresh() {
        viewModel.send(.refresh)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_refresh_whenFails_shouldShowError() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = try getAlert {
            self.viewModel.send(.refresh)
        }
        XCTAssertEqual(alert.title, "Failed to Refresh")
    }

    func test_refresh_isRefreshing_shouldEmitTrueThenFalse() {
        let values = viewModel.values.isRefreshing.dropFirst().wait {
            self.viewModel.send(.refresh)
        }
        XCTAssertEqual(values, [true, false])
    }

    // MARK: moreOptionsSelected

    private func getActivities(actions: @escaping () -> Void) throws -> [Activity] {
        let event = try viewModel.eventPublisher.first().wait(executing: actions).singleValue()
        return try extract(case: type(of: event).activities, from: event).0
    }

    func test_moreOptionsSelected_shouldEmitExpectedActivities() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    func test_moreOptionsSelected_withNoLabels_shouldEmitExpectedActivities() throws {
        labelsSubject.send([])
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    // MARK: moreOptionsSelected - Set Label

    func test_setLabelActivity_shouldEmitSelectionAlert() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        XCTAssertEqual(alert.actions.map(\.title), ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_whenOptionSelected_shouldCallImplementationSetLabelAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
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
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
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
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Verify Files" }?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_verifyFilesActivity_whenFails_shouldEmitAlert() throws {
        implementation.verifyResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Verify Files" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Verify Files")
    }

    // MARK: moreOptionsSelected - Move Download Folder

    func test_moveDownloadFolderActivity_shouldEmitMoveDownloadFolderEvent() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (path, _) = try extract(case: TorrentDetailViewModelEvent.moveDownloadFolder, from: event)
        XCTAssertEqual(path, "/downloads")
    }

    // swiftlint:disable:next line_length
    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_shouldCallImplementationMoveDownloadFolderAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (_, subject) = try extract(case: TorrentDetailViewModelEvent.moveDownloadFolder, from: event)
        subject.send("/new")
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath, ["/new"])
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andFails_shouldEmitAlert() throws {
        implementation.moveDownloadFolderResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (_, subject) = try extract(case: TorrentDetailViewModelEvent.moveDownloadFolder, from: event)
        let alert = try getAlert {
            subject.send("/new")
        }
        XCTAssertEqual(alert.title, "Failed to Move Download Folder")
    }

    // MARK: moreOptions - Update Trackers

    func test_updateTrackersActivity_shouldCallImplementationUpdateTrackersAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Update Trackers" }?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_updateTrackersActivity_whenFails_shouldEmitAlert() throws {
        implementation.updateTrackersResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Update Trackers")
    }

    // MARK: pauseSelected

    func test_pause_shouldCallImplementationPauseAndRefresh() {
        viewModel.send(.pauseSelected)
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_pause_whenFails_shouldEmitAlert() throws {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = try getAlert {
            self.viewModel.send(.pauseSelected)
        }
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    // MARK: resumeSelected

    func test_resume_shouldCallImplementationPauseAndRefresh() {
        viewModel.send(.resumeSelected)
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 1)
    }

    func test_resume_whenFails_shouldEmitAlert() throws {
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = try getAlert {
            self.viewModel.send(.resumeSelected)
        }
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    // MARK: removeSelected

    func test_removeSelected_shouldEmitAlert() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(source: .view(UIView(), rect: .zero)))
        }
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_whenKeepDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
    }

    func test_removeSelected_whenKeepDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = try getAlert {
            self.viewModel.send(.removeSelected(source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenRemoveDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
    }

    func test_removeSelected_whenRemoveDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = try getAlert {
            self.viewModel.send(.removeSelected(source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    // MARK: editSectionSelected

    func test_editSectionSelected_shouldEmitNewEditSection() throws {
        let editSection = try viewModel.values.editSection.dropFirst().first().wait {
            self.viewModel.send(.editSectionSelected(.files))
        }.singleValue()
        XCTAssertEqual(editSection, .files)
    }

    // MARK: doneEditingSelected

    func test_doneEditingSelected_shouldEmitNilEditSection() throws {
        let editSection = try viewModel.values.editSection.dropFirst().first().wait {
            self.viewModel.send(.doneEditingSelected)
        }.singleValue()
        XCTAssertNil(editSection)
    }

    // MARK: setFilePrioritySelected

    func test_setFilePrioritySelected_shouldEmitExpectedAlert() throws {
        _ = viewModel.values.sections.first().wait()
        let alert = try getAlert {
            self.viewModel.send(.setFilePrioritySelected(
                indexPaths: [.init(row: 0, section: 2)],
                source: .view(.init(), rect: .zero)
            ))
        }
        XCTAssertEqual(alert.title, L10n.Action.setPriority)
        XCTAssertEqual(alert.actions.map(\.title), [
            L10n.Priority.disabled,
            L10n.Priority.low,
            L10n.Priority.normal,
            L10n.Priority.high,
            L10n.Action.cancel,
        ])
    }

    // MARK: - Values

    // MARK: sections

    func test_sections_shouldHaveHeader() throws {
        let sections = try viewModel.values.sections.first().wait().singleValue()
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
                    try item.value.first().wait().singleValue(),
                    try item.expandedValue?.first().wait().singleValue()
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
        let section = try viewModel.values.sections.first().wait().singleValue()[1]
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
        torrentSubject.send(.mock(trackers: trackers))

        let section = try viewModel.values.sections.first().wait().singleValue()[2]
        XCTAssertEqual(section.type, .trackers)
        let extracted = try section.items.map { try extract(case: TorrentDetailItem.tracker, from: $0) }
        XCTAssertEqual(extracted, trackers)
    }

    func test_sections_files_shouldBeSorted() throws {
        let section = try viewModel.values.sections.first().wait().singleValue()[2]
        XCTAssertEqual(section.type, .files)
        let files = try section.items.map {
            try extract(case: TorrentDetailItem.file, from: $0).name.first().wait().singleValue()
        }
        XCTAssertEqual(files, ["file.r00", "file.r01", "file.rar"])
    }

    // MARK: eta

    func test_eta_whenZero_shouldFormatProperly() throws {
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let eta = try getInfoRows(in: sections[1]).first { $0.0 == "ETA" }?.1
        XCTAssertEqual(eta, "∞")
    }

    // MARK: ratio

    func test_ratio_whenInfinite_shouldFormatProperly() throws {
        torrentSubject.send(.mock(uploaded: 1))
        XCTAssertTrue(torrentSubject.value.ratio.isInfinite)
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let eta = try getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }?.1
        XCTAssertEqual(eta, "∞")
    }

    func test_ratio_whenNaN_shouldFormatProperly() throws {
        XCTAssertTrue(torrentSubject.value.ratio.isNaN)
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let eta = try getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }?.1
        XCTAssertEqual(eta, "∞")
    }

    // MARK: contextMenu

    func test_contextMenu_withoutFileIndexPath_shouldReturnNil() {
        _ = viewModel.values.sections.first().wait()
        XCTAssertNil(viewModel.values.contextMenu(.init(row: 0, section: 0)))
    }

    func test_contextMenu_withFileIndexPath_shouldReturnExpectedMenu() {
        _ = viewModel.values.sections.first().wait()
        guard let menu = viewModel.values.contextMenu(.init(row: 0, section: 2)) else {
            XCTFail("Expected menu")
            return
        }
        assertSnapshot(matching: menu, as: .dump)
    }

    func test_contextMenu_whenPrioritySelected_shouldCallImplementationSetPriorityAndRefreshFiles() throws {
        let pairs: [(String, TorrentPriority)] = [
            ("Disabled", .disabled),
            ("Low Priority", .low),
            ("Normal Priority", .normal),
            ("High Priority", .high),
        ]

        for (title, priority) in pairs {
            setUp()

            _ = viewModel.values.sections.first().wait()

            guard let menu = viewModel.values.contextMenu(.init(row: 0, section: 2)) else {
                XCTFail("Expected menu")
                continue
            }

            let actions = menu.children.compactMap { try? extract(case: MenuItem.action, from: $0) }
            guard let action = actions.first(where: { $0.title == title }) else {
                XCTFail("Actions did not contain \"\(title)\"")
                continue
            }

            action.handler()
            XCTAssertEqual(
                implementation.setPriorityParamPriorities.map { Array($0.values) },
                [[priority]],
                String(describing: action)
            )
            XCTAssertEqual(implementation.refreshFilesCallCount, 2, String(describing: action))
        }
    }

    func test_contextMenu_action_whenPriorityIsCurrent_shouldBeInOnState() throws {
        let pairs: [(String, TorrentPriority)] = [
            ("Disabled", .disabled),
            ("Low Priority", .low),
            ("Normal Priority", .normal),
            ("High Priority", .high),
        ]

        for (title, priority) in pairs {
            setUp()
            implementation.refreshFilesResult = Just([
                StandardTorrentFile.mock(index: 0, priority: priority),
            ]).setFailureType(to: Error.self).eraseToAnyPublisher()

            viewModel.send(.refresh)
            _ = viewModel.values.sections.first().wait()

            guard let menu = viewModel.values.contextMenu(.init(row: 0, section: 2)) else {
                XCTFail("Expected menu")
                continue
            }

            let actions = menu.children.compactMap { try? extract(case: MenuItem.action, from: $0) }
            guard let action = actions.first(where: { $0.title == title }) else {
                XCTFail("Actions did not contain \"\(title)\"")
                continue
            }

            XCTAssertEqual(action.state, .on, String(describing: action))
        }
    }

    func test_contextMenu_whenPrioritySelected_andFails_shouldEmitAlert() throws {
        implementation.setPriorityResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        _ = viewModel.values.sections.first().wait()

        let menu = viewModel.values.contextMenu(.init(row: 0, section: 2))
        let action = menu?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Disabled" }
        let alert = try getAlert {
            action?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Set Priority")
    }

    func test_contextMenu_whenRefreshFiles_shouldNotEmitAlert() {
        implementation.refreshFilesResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        _ = viewModel.values.sections.first().wait()

        let menu = viewModel.values.contextMenu(.init(row: 0, section: 2))
        let action = menu?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Disabled" }
        let event = viewModel.eventPublisher.first().wait {
            action?.handler()
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: toolbarInfo

    func test_toolbarInfo_whenNotEditing_shouldBeEmpty() throws {
        let toolbarInfo = try viewModel.values.toolbarInfo.first().wait().singleValue()
        XCTAssertTrue(toolbarInfo.isEmpty)
    }

    func test_toolbarInfo_whenEditingFiles_shouldBeSelectionCount() throws {
        viewModel.send(.editSectionSelected(.files))
        viewModel.send(.multiSelectUpdated(indexPaths: [.init(row: 0, section: 0)]))
        let toolbarInfo = try viewModel.values.toolbarInfo.first().wait().singleValue()
        XCTAssertEqual(toolbarInfo, "1 Selected")
    }

    func test_toolbarInfo_whenDoneEditing_shouldBeEmpty() throws {
        viewModel.send(.editSectionSelected(.files))
        viewModel.send(.multiSelectUpdated(indexPaths: [.init(row: 0, section: 0)]))
        viewModel.send(.doneEditingSelected)
        let toolbarInfo = try viewModel.values.toolbarInfo.first().wait().singleValue()
        XCTAssertTrue(toolbarInfo.isEmpty)
    }
}
