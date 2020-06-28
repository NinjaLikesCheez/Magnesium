import Combine
import CommonModels
import Deluge
@testable import Magnesium
import Preferences
import SnapshotTesting
import ViewModel
import XCTest

final class StandardTorrentListViewModelTests: TestCase {
    private var implementation: MockStandardTorrentListImplementation!
    private var viewModel: StandardTorrentListViewModel!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        implementation = MockStandardTorrentListImplementation()
        viewModel = StandardTorrentListViewModel(implementation: .mock(implementation), server: .mock(.deluge))
    }

    private func getAlert(actions: @escaping () -> Void) throws -> Alert {
        let event = try viewModel.eventPublisher.first().wait(executing: actions).singleValue()
        return try extract(case: type(of: event).alert, from: event)
    }

    // MARK: - Title

    func test_title_shouldBeExpectedTitle() {
        XCTAssertEqual(viewModel.values.title.first().wait(), "MockServer")
    }

    func test_title_whenEditing_shouldBeSelectionCount() {
        viewModel.send(.editSelected)
        XCTAssertEqual(viewModel.values.title.first().wait(), "0 Selected")
    }

    func test_title_whenEditingSelectionChanged_shouldUpdate() {
        viewModel.send(.editSelected)
        viewModel.send(.multiSelectUpdated(indices: [0, 1]))
        XCTAssertEqual(viewModel.values.title.first().wait(), "2 Selected")
    }

    func test_title_whenEditingEnded_shouldBeDefault() {
        viewModel.send(.editSelected)
        viewModel.send(.doneEditingSelected)
        XCTAssertEqual(viewModel.values.title.first().wait(), "MockServer")
    }

    // MARK: - Auto Refresh

    func test_autoRefresh_shouldFire() {
        preferences[.autoRefreshInterval] = 1

        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshCallCount, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        preferences[.autoRefreshInterval] = 1
        preferences[.autoRefreshInterval] = 0

        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    // MARK: - StandardTorrentListViewModelImplementation

    func test_implementation_updated_shouldUpdateItems() {
        let items = viewModel.values.items.dropFirst().first().wait {
            self.implementation.updatedSubject.send(([], []))
        }
        XCTAssertFalse(items.values().isEmpty)
    }

    // MARK: - Handle TorrentListViewEvent

    // MARK: refresh

    func test_refresh_shouldCallImplementationRefresh() {
        viewModel.send(.refresh)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_refresh_whenFails_shouldShowError() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.send(.refresh)
        }
        XCTAssertEqual(alert.title, "Failed to Refresh")
    }

    func test_refresh_isLoading_shouldEmitTrueThenFalse() {
        let values = viewModel.values.isLoading.dropFirst().wait {
            self.viewModel.send(.refresh)
        }
        XCTAssertEqual(values, [true, false])
    }

    func test_refresh_isLoading_whenFails_shouldEmitTrueThenFalse() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let values = viewModel.values.isLoading.dropFirst().wait {
            self.viewModel.send(.refresh)
        }
        XCTAssertEqual(values, [true, false])
    }

    func test_refresh_withNoChanges_shouldNotEmit() {
        let event = viewModel.eventPublisher.dropFirst().first().wait {
            self.viewModel.send(.refresh)
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    func test_refresh_withChanges_shouldEmitTorrentsUpdatedEvent() throws {
        implementation.refreshResult = Just(([.mock()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.refresh)
        }.singleValue()
        XCTAssertCase(event, type(of: event).torrentsUpdated)
    }

    // MARK: addSelected

    func test_addSelected_shouldEmitAddEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.addSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        XCTAssertCase(event, type(of: event).add)
    }

    func test_addLink_shouldCallImplementationAddLink() {
        viewModel.addLink("http://example.com")
        XCTAssertEqual(implementation.addLinkCallCount, 1)
        XCTAssertEqual(implementation.addLinkParamURL, ["http://example.com"])
    }

    func test_addLink_whenFails_shouldEmitAlert() throws {
        implementation.addLinkResult = Fail(error: .init(
            title: "ErrorTitle",
            message: "ErrorMessage"
        )).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.addLink("http://example.com")
        }
        XCTAssertEqual(alert.title, "ErrorTitle")
        XCTAssertEqual(alert.message, "ErrorMessage")
        XCTAssertEqual(alert.actions.map(\.title), ["OK"])
    }

    // MARK: filterSelected

    func test_filterSelected_shouldEmitFilterEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.filterSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        XCTAssertCase(event, type(of: event).filter)
    }

    // MARK: itemSelected

    func test_itemSelected_shouldEmitDetailEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.itemSelected(index: 0))
        }.singleValue()
        XCTAssertCase(event, type(of: event).detail)
        XCTAssertEqual(implementation.detailViewModelCallCount, 1)
        XCTAssertEqual(implementation.detailViewModelParamTorrent.map(\.value.name), ["Mock"])
        XCTAssertEqual(implementation.detailViewModelParamLabels[0].value.map(\.name), ["", "label1", "label2"])
    }

    // MARK: settingsSelected

    func test_settingsSelected_shouldEmitSettingsEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.settingsSelected)
        }.singleValue()
        XCTAssertCase(event, .settings)
    }

    // MARK: search

    func test_search_shouldUpdateItems() throws {
        implementation.refreshResult = Just(([
            .mock(dateAdded: Date(timeIntervalSinceNow: 0), hash: "A", name: "test torrent"),
            .mock(dateAdded: Date(timeIntervalSinceNow: -1), hash: "B", name: "example"),
            .mock(dateAdded: Date(timeIntervalSinceNow: -2), hash: "C", name: "TEST.TORRENT"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.send(.refresh)
        let items = try viewModel.values.items.dropFirst().first().wait {
            self.viewModel.send(.search(query: "test tor"))
        }.singleValue()
        let names = try items.map { try $0.name.first().wait().singleValue() }
        XCTAssertEqual(names, ["test torrent", "TEST.TORRENT"])
    }

    // MARK: resumeSelected

    func test_resumeSelected_shouldCallImplementationResumeAndRefresh() {
        viewModel.send(.resumeSelected(indices: [0, 1]))
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.resumeParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_resumeSelected_whenFails_shouldEmitAlert() throws {
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.send(.resumeSelected(indices: [0, 1]))
        }
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    func test_resumeSelected_whenRefreshFails_shouldNotEmitAlert() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let event = viewModel.eventPublisher.first().wait {
            self.viewModel.send(.resumeSelected(indices: [0, 1]))
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: pauseSelected

    func test_pauseSelected_shouldCallImplementationPauseAndRefresh() {
        viewModel.send(.pauseSelected(indices: [0, 1]))
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.pauseParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_pauseSelected_whenFails_shouldEmitAlert() throws {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.send(.pauseSelected(indices: [0, 1]))
        }
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    func test_pauseSelected_whenRefreshFails_shouldNotEmitAlert() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let event = viewModel.eventPublisher.first().wait {
            self.viewModel.send(.pauseSelected(indices: [0, 1]))
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: removeSelected

    func test_removeSelected_withSingleTorrent_shouldEmitAlert() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_withMultipleTorrents_shouldEmitAlert() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "2 Torrents")
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_whenKeepDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
    }

    func test_removeSelected_whenKeepDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenKeepDataSelected_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.eventPublisher.first().wait {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    func test_removeSelected_whenRemoveDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
    }

    func test_removeSelected_whenRemoveDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenRemoveDataSelected_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.send(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.eventPublisher.first().wait {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: moreOptionsSelected

    private func getActivities(actions: @escaping () -> Void) throws -> [Activity] {
        let event = try viewModel.eventPublisher.first().wait(executing: actions).singleValue()
        return try extract(case: type(of: event).activities, from: event).0
    }

    func test_moreOptionsSelected_shouldEmitExpectedActivities() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    func test_moreOptionsSelected_withNoLabels_shouldEmitExpectedActivities() throws {
        implementation.refreshResult = Just(([.mock()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.send(.refresh)
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    // MARK: moreOptionsSelected - Set Label

    func test_setLabelActivity_withSingleTorrent_shouldEmitSelectionAlert() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        XCTAssertEqual(alert.title, "Set Label")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map(\.title), ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_withMultipleTorrents_shouldEmitSelectionAlert() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        XCTAssertEqual(alert.title, "Set Label")
        XCTAssertEqual(alert.message, "2 Torrents")
        XCTAssertEqual(alert.actions.map(\.title), ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_whenOptionSelected_shouldCallImplementationSetLabelAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        alert.actions.first { $0.title == "label1" }?.handler?()
        XCTAssertEqual(implementation.setLabelCallCount, 1)
        XCTAssertEqual(implementation.setLabelParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.setLabelParamLabel[0].name, "label1")
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_setLabelActivity_whenOptionSelected_andFails_shouldEmitAlert() throws {
        implementation.setLabelResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let optionsAlert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "label1" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Set Label")
    }

    func test_setLabelActivity_whenOptionSelected_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let optionsAlert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }

        let event = viewModel.eventPublisher.first().wait {
            optionsAlert.actions.first { $0.title == "label1" }?.handler?()
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: moreOptionsSelected - Verify Files

    func test_verifyFilesActivity_shouldCallImplementationVerifyFilesAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Verify Files" }?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.verifyParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_verifyFilesActivity_whenFails_shouldEmitAlert() throws {
        implementation.verifyResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Verify Files" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Verify Files")
    }

    func test_verifyFilesActivity_whenRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Verify Files" }?.handler()
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: moreOptionsSelected - Move Download Folder

    func test_moveDownloadFolderActivity_shouldEmitMoveDownloadFolderEvent() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        XCTAssertCase(event, type(of: event).moveDownloadFolder)
    }

    func test_moveDownloadFolderActivity_withSameDownloadPath_shouldHaveCurrentPath() throws {
        implementation.refreshResult = Just(([
            .mock(downloadPath: "/downloads"),
            .mock(downloadPath: "/downloads"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.send(.refresh)
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (path, _) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        XCTAssertEqual(path, "/downloads")
    }

    func test_moveDownloadFolderActivity_withDifferentDownloadPaths_shouldHaveNilCurrentPath() throws {
        implementation.refreshResult = Just(([
            .mock(downloadPath: "/downloads"),
            .mock(downloadPath: "/downloads2"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.send(.refresh)
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (path, _) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        XCTAssertNil(path)
    }

    // swiftlint:disable:next line_length
    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_shouldCallImplementationMoveDownloadFolderAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (_, subject) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        subject.send("/new")
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath, ["/new"])
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andFails_shouldEmitAlert() throws {
        implementation.moveDownloadFolderResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (_, subject) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        let alert = try getAlert {
            subject.send("/new")
        }
        XCTAssertEqual(alert.title, "Failed to Move Download Folder")
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let moveEvent = try viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.singleValue()
        let (_, subject) = try extract(case: type(of: moveEvent).moveDownloadFolder, from: moveEvent)

        let event = viewModel.eventPublisher.first().wait {
            subject.send("/new")
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: moreOptionsSelected - Update Trackers

    func test_updateTrackersActivity_shouldCallImplementationUpdateTrackersAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Update Trackers" }?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.updateTrackersParamTorrents.map { $0.map(\.name) }, [["Mock", "Mock 2"]])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_updateTrackersActivity_whenFails_shouldEmitAlert() throws {
        implementation.updateTrackersResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Update Trackers")
    }

    func test_updateTrackersActivity_whenRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.send(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.eventPublisher.first().wait {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    // MARK: - Values

    // MARK: items

    func test_items_shouldEmitInitialValue() {
        XCTAssertFalse(viewModel.values.items.first().wait().values().isEmpty)
    }

    func test_items_shouldRemoveDuplicates() {
        let items = viewModel.values.items.dropFirst().first().wait {
            self.viewModel.send(.refresh)
        }
        XCTAssertTrue(items.values().isEmpty)
    }

    func test_items_shouldEmitNewValues() {
        implementation.refreshResult = Just(([.mock()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        let items = viewModel.values.items.dropFirst().first().wait {
            self.viewModel.send(.refresh)
        }
        XCTAssertFalse(items.values().isEmpty)
    }

    // MARK: hasActiveFilters

    func test_hasActiveFilters_withNoFilters_shouldBeFalse() throws {
        XCTAssertFalse(try viewModel.values.hasActiveFilters.first().wait().singleValue())
    }

    func test_hasActiveFilters_withFilters_shouldBeTrue() {
        preferences[.filterOptions] = FilterOptions(state: .downloading)
        XCTAssertTrue(try viewModel.values.hasActiveFilters.first().wait(timeout: 1).singleValue())
    }

    // MARK: status

    func test_status_shouldBeTotalSpeeds() {
        implementation.refreshResult = Just(([
            .mock(downloadRate: 100_000, label: "label1", uploadRate: 200_000),
            .mock(downloadRate: 200_000, label: "label2", uploadRate: 400_000),
            .mock(downloadRate: 400_000, label: "label1", uploadRate: 800_000),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.send(.refresh)
        preferences[.filterOptions] = FilterOptions(label: "label2")
        XCTAssertEqual(viewModel.values.status.first().wait(), "↓ 684 KB/s ↑ 1.3 MB/s")
    }

    // MARK: detailViewModel

    func test_detailViewModel_shouldReturnExpectedViewModel() {
        XCTAssertNotNil(viewModel.values.detailViewModel(.mock(hash: "A")))
    }

    // MARK: contextMenu

    func test_contextMenu_whenNoLabels_shouldReturnExpectedMenu() {
        implementation.refreshResult = Just(([.mock(hash: "A")], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.send(.refresh)

        guard let menu = viewModel.values.contextMenu(.mock(hash: "A")) else {
            XCTFail("Expected menu")
            return
        }

        assertSnapshot(matching: menu, as: .dump)
    }

    func test_contextMenu_withActiveTorrent_shouldReturnExpectedMenu() {
        guard let menu = viewModel.values.contextMenu(.mock(hash: "A")) else {
            XCTFail("Expected menu")
            return
        }

        assertSnapshot(matching: menu, as: .dump)
    }

    func test_contextMenu_withInactiveTorrent_shouldReturnExpectedMenu() {
        implementation.refreshResult = Just((
            [.mock(hash: "A", state: .paused)],
            [.mock(name: ""), .mock(name: "label1"), .mock(name: "label2")]
        ))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.send(.refresh)

        guard let menu = viewModel.values.contextMenu(.mock(hash: "A")) else {
            XCTFail("Expected menu")
            return
        }

        assertSnapshot(matching: menu, as: .dump)
    }

    func test_contextMenu_pause_shouldPauseAndRefresh() {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Pause" }
        action?.handler()
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_contextMenu_resume_shouldResumeAndRefresh() {
        implementation.refreshResult = Just(([.mock(hash: "A", name: "Mock", state: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.send(.refresh)

        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Resume" }
        action?.handler()
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 3)
    }

    func test_contextMenu_setLabel_shouldSetLabelAndRefresh() throws {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.menu, from: $0) }
            .first?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "label1" }
        action?.handler()
        XCTAssertEqual(implementation.setLabelCallCount, 1)
        XCTAssertEqual(implementation.setLabelParamLabel, [.mock(name: "label1")])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_contextMenu_verifyFiles_shouldVerifyFilesAndRefresh() {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Verify Files" }
        action?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_contextMenu_moveDownloadFolder_shouldMoveDownloadFolderAndRefresh() throws {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Move Download Folder" }
        let event = try viewModel.eventPublisher.first().wait {
            action?.handler()
        }.singleValue()
        let (_, subject) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        subject.send("/new")
        subject.send(completion: .finished)
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath, ["/new"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_contextMenu_updateTrackers_shouldUpdateTrackersAndRefresh() {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Update Trackers" }
        action?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_contextMenu_remove_keepData_shouldRemoveAndRefresh() {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.menu, from: $0) }
            .first { $0.title == "Remove" }?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Keep Data" }
        action?.handler()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_contextMenu_remove_removeData_shouldRemoveAndRefresh() {
        let action = viewModel.values.contextMenu(.mock(hash: "A"))?.children
            .compactMap { try? extract(case: MenuItem.menu, from: $0) }
            .first { $0.title == "Remove" }?.children
            .compactMap { try? extract(case: MenuItem.action, from: $0) }
            .first { $0.title == "Remove Data" }
        action?.handler()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    // MARK: leadingSwipeActionsConfiguration

    func test_leadingSwipeActionsConfiguration_whenTorrentIsActive_shouldReturnedExpectedConfiguration() {
        let config = viewModel.values.leadingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        XCTAssertEqual(config?.actions.map(\.image), [UIImage(systemName: "pause.fill")])
        XCTAssertEqual(config?.actions.map(\.backgroundColor), [.systemBlue])
        XCTAssertEqual(config?.actions.map(\.style), [.normal])
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsInactive_shouldReturnedExpectedConfiguration() {
        implementation.refreshResult = Just(([.mock(hash: "A", state: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.send(.refresh)

        let config = viewModel.values.leadingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        XCTAssertEqual(config?.actions.map(\.image), [UIImage(systemName: "play.fill")])
        XCTAssertEqual(config?.actions.map(\.backgroundColor), [.systemBlue])
        XCTAssertEqual(config?.actions.map(\.style), [.normal])
    }

    func test_pauseSwipeAction_shouldCallImplementationPauseAndRefresh() {
        let config = viewModel.values.leadingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        config?.actions[0].handler()
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_pauseSwipeAction_whenFails_shouldEmitAlert() throws {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let config = viewModel.values.leadingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        let alert = try getAlert {
            config?.actions[0].handler()
        }
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    func test_resumeSwipeAction_shouldCallImplementationResumeAndRefresh() {
        implementation.refreshResult = Just(([.mock(hash: "A", name: "Mock", state: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.send(.refresh)

        let config = viewModel.values.leadingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        config?.actions[0].handler()
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.refreshCallCount, 3)
    }

    func test_resumeSwipeAction_whenFails_shouldEmitAlert() throws {
        implementation.refreshResult = Just(([.mock(hash: "A", name: "Mock", state: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.send(.refresh)
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let config = viewModel.values.leadingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        let alert = try getAlert {
            config?.actions[0].handler()
        }
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    // MARK: trailingSwipeActionsConfiguration

    func test_trailingSwipeActionsConfiguration_shouldReturnExpectedConfiguration() {
        let config = viewModel.values.trailingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        let expected = [UIImage(systemName: "trash.fill"), UIImage(systemName: "ellipsis.circle.fill")]
        XCTAssertEqual(config?.actions.map(\.image), expected)
        XCTAssertEqual(config?.actions.map(\.backgroundColor), [nil, .systemGray])
        XCTAssertEqual(config?.actions.map(\.style), [.destructive, .normal])
    }

    func test_moreSwipeAction_shouldEmitActivities() throws {
        let config = viewModel.values.trailingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        let activities = try getActivities {
            config?.actions[1].handler()
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    func test_removeSwipeAction_shouldCallImplementationRemoveAndRefresh() throws {
        let config = viewModel.values.trailingSwipeActionsConfiguration(.mock(hash: "A"), .view(UIView(), rect: .zero))
        let alert = try getAlert {
            config?.actions[0].handler()
        }
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }
}
