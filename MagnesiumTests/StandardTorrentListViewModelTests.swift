import Combine
import CommonModels
import Deluge
@testable import Magnesium
import Preferences
import ViewModel
import XCTest

final class StandardTorrentListViewModelTests: XCTestCase {
    private var implementation: MockImplementation!
    private var viewModel: StandardTorrentListViewModel<MockImplementation>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        implementation = MockImplementation()
        viewModel = StandardTorrentListViewModel(implementation: implementation, server: .mock(.deluge))
    }

    private func getAlert(actions: @escaping () -> Void) throws -> Alert {
        let event = try viewModel.events.first().wait(executing: actions).value()
        return try extract(case: type(of: event).alert, from: event)
    }

    // MARK: - Title

    func test_title_shouldBeExpectedTitle() {
        XCTAssertEqual(viewModel.view.title.first().wait(), "MockServer")
    }

    func test_title_whenEditing_shouldBeSelectionCount() {
        viewModel.receive(.editSelected)
        XCTAssertEqual(viewModel.view.title.first().wait(), "0 Selected")
    }

    func test_title_whenEditingSelectionChanged_shouldUpdate() {
        viewModel.receive(.editSelected)
        viewModel.receive(.multiSelectUpdated(indices: [0, 1]))
        XCTAssertEqual(viewModel.view.title.first().wait(), "2 Selected")
    }

    func test_title_whenEditingEnded_shouldBeDefault() {
        viewModel.receive(.editSelected)
        viewModel.receive(.doneEditingSelected)
        XCTAssertEqual(viewModel.view.title.first().wait(), "MockServer")
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
        let items = viewModel.view.items.dropFirst().first().wait {
            self.implementation.updatedSubject.send(([], []))
        }
        XCTAssertTrue(items.hasValue())
    }

    // MARK: - Handle TorrentListViewEvent

    // MARK: refresh

    func test_refresh_shouldCallImplementationRefresh() {
        viewModel.receive(.refresh)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_refresh_whenFails_shouldShowError() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.receive(.refresh)
        }
        XCTAssertEqual(alert.title, "Update Failed")
    }

    func test_refresh_isLoading_shouldEmitTrueThenFalse() {
        let values = viewModel.view.isLoading.dropFirst().wait {
            self.viewModel.receive(.refresh)
        }
        XCTAssertEqual(values, [true, false])
    }

    func test_refresh_isLoading_whenFails_shouldEmitTrueThenFalse() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let values = viewModel.view.isLoading.dropFirst().wait {
            self.viewModel.receive(.refresh)
        }
        XCTAssertEqual(values, [true, false])
    }

    func test_refresh_withNoChanges_shouldNotEmit() {
        let event = viewModel.events.dropFirst().first().wait {
            self.viewModel.receive(.refresh)
        }
        XCTAssertFalse(event.hasValue())
    }

    func test_refresh_withChanges_shouldEmitTorrentsUpdatedEvent() throws {
        implementation.refreshResult = Just(([MockTorrent()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.refresh)
        }.value()
        XCTAssertCase(event, type(of: event).torrentsUpdated)
    }

    // MARK: addSelected

    func test_addSelected_shouldEmitAddEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.addSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        XCTAssertCase(event, type(of: event).add)
    }

    func test_addLink_shouldCallImplementationAddLink() {
        viewModel.addLink("http://example.com")
        XCTAssertEqual(implementation.addLinkCallCount, 1)
        XCTAssertEqual(implementation.addLinkParamURL, ["http://example.com"])
    }

    func test_addLink_whenFails_shouldEmitAlert() throws {
        implementation.addLinkResult = Just(("ErrorTitle", "ErrorMessage")).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.addLink("http://example.com")
        }
        XCTAssertEqual(alert.title, "ErrorTitle")
        XCTAssertEqual(alert.message, "ErrorMessage")
        XCTAssertEqual(alert.actions.map(\.title), ["OK"])
    }

    // MARK: filterSelected

    func test_filterSelected_shouldEmitFilterEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.filterSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        XCTAssertCase(event, type(of: event).filter)
    }

    // MARK: itemSelected

    func test_itemSelected_shouldEmitDetailEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.itemSelected(index: 0))
        }.value()
        XCTAssertCase(event, type(of: event).detail)
        XCTAssertEqual(implementation.detailViewModelCallCount, 1)
        XCTAssertEqual(implementation.detailViewModelParamTorrent.map(\.value.name), ["Mock"])
        XCTAssertEqual(implementation.detailViewModelParamLabels[0].value.map(\.name), ["", "label1", "label2"])
    }

    // MARK: settingsSelected

    func test_settingsSelected_shouldEmitSettingsEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.settingsSelected)
        }.value()
        XCTAssertCase(event, type(of: event).settings)
    }

    // MARK: search

    func test_search_shouldUpdateItems() throws {
        implementation.refreshResult = Just(([
            MockTorrent(hash: "A", name: "test torrent", dateAdded: Date(timeIntervalSinceNow: 0)),
            MockTorrent(hash: "B", name: "example", dateAdded: Date(timeIntervalSinceNow: -1)),
            MockTorrent(hash: "C", name: "TEST.TORRENT", dateAdded: Date(timeIntervalSinceNow: -2)),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.receive(.refresh)
        let items = try viewModel.view.items.dropFirst().first().wait {
            self.viewModel.receive(.search(query: "test tor"))
        }.value()
        let names = try items.map { try $0.name.first().wait().value() }
        XCTAssertEqual(names, ["test torrent", "TEST.TORRENT"])
    }

    // MARK: resumeSelected

    func test_resumeSelected_shouldCallImplementationResumeAndRefresh() {
        viewModel.receive(.resumeSelected(indices: [0, 1]))
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.resumeParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_resumeSelected_whenFails_shouldEmitAlert() throws {
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.receive(.resumeSelected(indices: [0, 1]))
        }
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    func test_resumeSelected_whenRefreshFails_shouldNotEmitAlert() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let event = viewModel.events.first().wait {
            self.viewModel.receive(.resumeSelected(indices: [0, 1]))
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: pauseSelected

    func test_pauseSelected_shouldCallImplementationPauseAndRefresh() {
        viewModel.receive(.pauseSelected(indices: [0, 1]))
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.pauseParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_pauseSelected_whenFails_shouldEmitAlert() throws {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let alert = try getAlert {
            self.viewModel.receive(.pauseSelected(indices: [0, 1]))
        }
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    func test_pauseSelected_whenRefreshFails_shouldNotEmitAlert() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let event = viewModel.events.first().wait {
            self.viewModel.receive(.pauseSelected(indices: [0, 1]))
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: removeSelected

    func test_removeSelected_withSingleTorrent_shouldEmitAlert() throws {
        let alert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_withMultipleTorrents_shouldEmitAlert() throws {
        let alert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "2 Torrents")
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_whenKeepDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
    }

    func test_removeSelected_whenKeepDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenKeepDataSelected_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.events.first().wait {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }
        XCTAssertFalse(event.hasValue())
    }

    func test_removeSelected_whenRemoveDataSelected_shouldCallImplementationRemoveAndRefresh() throws {
        let alert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        alert.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
    }

    func test_removeSelected_whenRemoveDataSelected_andFails_shouldEmitAlert() throws {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let errorAlert = try getAlert {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenRemoveDataSelected_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let optionsAlert = try getAlert {
            self.viewModel.receive(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.events.first().wait {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: moreOptionsSelected

    private func getActivities(actions: @escaping () -> Void) throws -> [Activity] {
        let event = try viewModel.events.first().wait(executing: actions).value()
        return try extract(case: type(of: event).activities, from: event).0
    }

    func test_moreOptionsSelected_shouldEmitExpectedActivities() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    func test_moreOptionsSelected_withNoLabels_shouldEmitExpectedActivities() throws {
        implementation.refreshResult = Just(([MockTorrent()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.receive(.refresh)
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }
        let expected = ["Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    // MARK: moreOptionsSelected - Set Label

    func test_setLabelActivity_withSingleTorrent_shouldEmitSelectionAlert() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
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
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
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
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }
        alert.actions.first { $0.title == "label1" }?.handler?()
        XCTAssertEqual(implementation.setLabelCallCount, 1)
        XCTAssertEqual(implementation.setLabelParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.setLabelParamLabel[0].name, "label1")
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_setLabelActivity_whenOptionSelected_andFails_shouldEmitAlert() throws {
        implementation.setLabelResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
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
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let optionsAlert = try getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }

        let event = viewModel.events.first().wait {
            optionsAlert.actions.first { $0.title == "label1" }?.handler?()
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: moreOptionsSelected - Verify Files

    func test_verifyFilesActivity_shouldCallImplementationVerifyFilesAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Verify Files" }?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.verifyParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_verifyFilesActivity_whenFails_shouldEmitAlert() throws {
        implementation.verifyResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Verify Files" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Verify Files")
    }

    func test_verifyFilesActivity_whenRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.events.first().wait {
            activities.first { $0.title == "Verify Files" }?.handler()
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: moreOptionsSelected - Move Download Folder

    func test_moveDownloadFolderActivity_shouldEmitMoveDownloadFolderEvent() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        XCTAssertCase(event, type(of: event).moveDownloadFolder)
    }

    func test_moveDownloadFolderActivity_withSameDownloadPath_shouldHaveCurrentPath() throws {
        implementation.refreshResult = Just(([
            MockTorrent(downloadPath: "/downloads"),
            MockTorrent(downloadPath: "/downloads"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.receive(.refresh)
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (path, _) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        XCTAssertEqual(path, "/downloads")
    }

    func test_moveDownloadFolderActivity_withDifferentDownloadPaths_shouldHaveNilCurrentPath() throws {
        implementation.refreshResult = Just(([
            MockTorrent(downloadPath: "/downloads"),
            MockTorrent(downloadPath: "/downloads2"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        viewModel.receive(.refresh)
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (path, _) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        XCTAssertNil(path)
    }

    // swiftlint:disable:next line_length
    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_shouldCallImplementationMoveDownloadFolderAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (_, subject) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        subject.send("/new")
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath, ["/new"])
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andFails_shouldEmitAlert() throws {
        implementation.moveDownloadFolderResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let event = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (_, subject) = try extract(case: type(of: event).moveDownloadFolder, from: event)
        let alert = try getAlert {
            subject.send("/new")
        }
        XCTAssertEqual(alert.title, "Failed to Move Download Folder")
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let moveEvent = try viewModel.events.first().wait {
            activities.first { $0.title == "Move Download Folder" }?.handler()
        }.value()
        let (_, subject) = try extract(case: type(of: moveEvent).moveDownloadFolder, from: moveEvent)

        let event = viewModel.events.first().wait {
            subject.send("/new")
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: moreOptionsSelected - Update Trackers

    func test_updateTrackersActivity_shouldCallImplementationUpdateTrackersAndRefresh() throws {
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        activities.first { $0.title == "Update Trackers" }?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.updateTrackersParamTorrents[0].map(\.name), ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_updateTrackersActivity_whenFails_shouldEmitAlert() throws {
        implementation.updateTrackersResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }
        let alert = try getAlert {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }
        XCTAssertEqual(alert.title, "Failed to Update Trackers")
    }

    func test_updateTrackersActivity_whenRefreshFails_shouldNotEmitAlert() throws {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let activities = try getActivities {
            self.viewModel.receive(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }

        let event = viewModel.events.first().wait {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }
        XCTAssertFalse(event.hasValue())
    }

    // MARK: - State

    // MARK: items

    func test_items_shouldEmitInitialValue() {
        XCTAssertTrue(viewModel.view.items.first().wait().hasValue())
    }

    func test_items_shouldRemoveDuplicates() {
        let items = viewModel.view.items.dropFirst().first().wait {
            self.viewModel.receive(.refresh)
        }
        XCTAssertFalse(items.hasValue())
    }

    func test_items_shouldEmitNewValues() {
        implementation.refreshResult = Just(([MockTorrent()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()

        let items = viewModel.view.items.dropFirst().first().wait {
            self.viewModel.receive(.refresh)
        }
        XCTAssertTrue(items.hasValue())
    }

    // MARK: hasActiveFilters

    func test_hasActiveFilters_withNoFilters_shouldBeFalse() throws {
        XCTAssertFalse(try viewModel.view.hasActiveFilters.first().wait().value())
    }

    func test_hasActiveFilters_withFilters_shouldBeTrue() {
        preferences[.filterOptions] = FilterOptions(state: .downloading)
        XCTAssertTrue(try viewModel.view.hasActiveFilters.first().wait(timeout: 1).value())
    }

    // MARK: status

    func test_status_shouldBeTotalSpeeds() {
        implementation.refreshResult = Just(([
            MockTorrent(downloadRate: 100_000, uploadRate: 200_000, label: "label1"),
            MockTorrent(downloadRate: 200_000, uploadRate: 400_000, label: "label2"),
            MockTorrent(downloadRate: 400_000, uploadRate: 800_000, label: "label1"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.receive(.refresh)
        preferences[.filterOptions] = FilterOptions(label: "label2")
        XCTAssertEqual(viewModel.view.status.first().wait(), "↓ 684 KB/s ↑ 1.3 MB/s")
    }

    // MARK: - TorrentListProvider

    func test_detailViewModelForItem_shouldReturnExpectedViewModel() {
        let detailViewModel = viewModel.detailViewModelForItem(at: 0)!.base as AnyObject
        guard type(of: detailViewModel) === MockDetailViewModel.self else {
            XCTFail("Unexpected view model: \(String(describing: viewModel))")
            return
        }
    }

    func test_contextMenuForItem_whenNoLabels_shouldReturnExpectedMenu() {
        implementation.refreshResult = Just(([MockTorrent()], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.receive(.refresh)

        let menu = viewModel.contextMenuForItem(at: 0)!
        func menuString(_ menu: UIMenuElement, level: Int = 0) -> String {
            var output = String(repeating: " ", count: level * 2)
            output += "\(menu.title)\n"
            if let menu = menu as? UIMenu {
                output += menu.children
                    .map { menuString($0, level: level + 1) }
                    .joined()
            }
            return output
        }
        // swiftformat:disable indent
        let expected = """

              Pause
              Verify Files
              Move Download Folder
              Update Trackers
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable indent
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_contextMenuForItem_withActiveTorrent_shouldReturnExpectedMenu() {
        let menu = viewModel.contextMenuForItem(at: 0)!
        func menuString(_ menu: UIMenuElement, level: Int = 0) -> String {
            var output = String(repeating: " ", count: level * 2)
            output += "\(menu.title)\n"
            if let menu = menu as? UIMenu {
                output += menu.children
                    .map { menuString($0, level: level + 1) }
                    .joined()
            }
            return output
        }
        // swiftformat:disable indent
        let expected = """

              Pause
              Set Label
                None
                label1
                label2
              Verify Files
              Move Download Folder
              Update Trackers
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable indent
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_contextMenuForItem_withInactiveTorrent_shouldReturnExpectedMenu() {
        implementation.refreshResult = Just((
            [MockTorrent(standardState: .paused)],
            [MockLabel(name: ""), MockLabel(name: "label1"), MockLabel(name: "label2")]
        ))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.receive(.refresh)

        let menu = viewModel.contextMenuForItem(at: 0)!
        func menuString(_ menu: UIMenuElement, level: Int = 0) -> String {
            var output = String(repeating: " ", count: level * 2)
            output += "\(menu.title)\n"
            if let menu = menu as? UIMenu {
                output += menu.children
                    .map { menuString($0, level: level + 1) }
                    .joined()
            }
            return output
        }
        // swiftformat:disable indent
        let expected = """

              Resume
              Set Label
                None
                label1
                label2
              Verify Files
              Move Download Folder
              Update Trackers
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable indent
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsActive_shouldReturnedExpectedConfiguration() {
        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        XCTAssertEqual(config?.actions.map(\.image), [UIImage(systemName: "pause.fill")])
        XCTAssertEqual(config?.actions.map(\.backgroundColor), [.systemBlue])
        XCTAssertEqual(config?.actions.map(\.style), [.normal])
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsInactive_shouldReturnedExpectedConfiguration() {
        implementation.refreshResult = Just(([MockTorrent(standardState: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.receive(.refresh)

        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        XCTAssertEqual(config?.actions.map(\.image), [UIImage(systemName: "play.fill")])
        XCTAssertEqual(config?.actions.map(\.backgroundColor), [.systemBlue])
        XCTAssertEqual(config?.actions.map(\.style), [.normal])
    }

    func test_pauseSwipeAction_shouldCallImplementationPauseAndRefresh() {
        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        config?.actions[0].handler()
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.pauseParamTorrents[0].map(\.name), ["Mock"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_pauseSwipeAction_whenFails_shouldEmitAlert() throws {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let alert = try getAlert {
            config?.actions[0].handler()
        }
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    func test_resumeSwipeAction_shouldCallImplementationResumeAndRefresh() {
        implementation.refreshResult = Just(([MockTorrent(name: "Mock", standardState: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.receive(.refresh)

        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        config?.actions[0].handler()
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.resumeParamTorrents[0].map(\.name), ["Mock"])
        XCTAssertEqual(implementation.refreshCallCount, 3)
    }

    func test_resumeSwipeAction_whenFails_shouldEmitAlert() throws {
        implementation.refreshResult = Just(([MockTorrent(name: "Mock", standardState: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.receive(.refresh)
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let alert = try getAlert {
            config?.actions[0].handler()
        }
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    func test_trailingSwipeActionsConfiguration_shouldReturnExpectedConfiguration() {
        let config = viewModel.trailingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let expected = [UIImage(systemName: "trash.fill"), UIImage(systemName: "ellipsis.circle.fill")]
        XCTAssertEqual(config?.actions.map(\.image), expected)
        XCTAssertEqual(config?.actions.map(\.backgroundColor), [nil, .systemGray])
        XCTAssertEqual(config?.actions.map(\.style), [.destructive, .normal])
    }

    func test_moreSwipeAction_shouldEmitActivities() throws {
        let config = viewModel.trailingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let activities = try getActivities {
            config?.actions[1].handler()
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map(\.title), expected)
    }

    func test_removeSwipeAction_shouldCallImplementationRemoveAndRefresh() throws {
        let config = viewModel.trailingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let alert = try getAlert {
            config?.actions[0].handler()
        }
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map(\.title), ["Keep Data", "Remove Data", "Cancel"])
    }
}

// MARK: - Mocks

private final class MockImplementation: StandardTorrentListViewModelImplementation {
    typealias Torrent = MockTorrent
    typealias Label = MockLabel

    let updatedSubject = PassthroughSubject<([MockTorrent], [MockLabel]), Never>()

    var updated: AnyPublisher<([MockTorrent], [MockLabel]), Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    private(set) var refreshCallCount = 0
    var refreshResult = Just((
        [
            MockTorrent(name: "Mock", dateAdded: Date()),
            MockTorrent(name: "Mock 2", dateAdded: Date(timeIntervalSinceNow: -1)),
        ],
        [MockLabel(name: ""), MockLabel(name: "label1"), MockLabel(name: "label2")]
    )).setFailureType(to: Error.self).eraseToAnyPublisher()
    func refresh() -> AnyPublisher<([MockTorrent], [MockLabel]), Error> {
        refreshCallCount += 1
        return refreshResult
    }

    private(set) var detailViewModelCallCount = 0
    private(set) var detailViewModelParamTorrent = [CurrentValueSubject<MockTorrent, Never>]()
    private(set) var detailViewModelParamLabels = [CurrentValueSubject<[MockLabel], Never>]()
    var detailViewModelResult = AnyViewModel(MockDetailViewModel())
    func detailViewModel(
        for torrent: CurrentValueSubject<MockTorrent, Never>,
        labels: CurrentValueSubject<[MockLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        detailViewModelCallCount += 1
        detailViewModelParamTorrent.append(torrent)
        detailViewModelParamLabels.append(labels)
        return detailViewModelResult
    }

    private(set) var addLinkCallCount = 0
    private(set) var addLinkParamURL = [String]()
    var addLinkResult = Empty<(String, String), Never>(completeImmediately: true).eraseToAnyPublisher()
    func addLink(_ url: String) -> AnyPublisher<(String, String), Never> {
        addLinkCallCount += 1
        addLinkParamURL.append(url)
        return addLinkResult
    }

    private(set) var pauseCallCount = 0
    private(set) var pauseParamTorrents = [[MockTorrent]]()
    var pauseResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func pause(_ torrents: [MockTorrent]) -> AnyPublisher<Void, Error> {
        pauseCallCount += 1
        pauseParamTorrents.append(torrents)
        return pauseResult
    }

    private(set) var resumeCallCount = 0
    private(set) var resumeParamTorrents = [[MockTorrent]]()
    var resumeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func resume(_ torrents: [MockTorrent]) -> AnyPublisher<Void, Error> {
        resumeCallCount += 1
        resumeParamTorrents.append(torrents)
        return resumeResult
    }

    private(set) var removeCallCount = 0
    private(set) var removeParamTorrents = [[MockTorrent]]()
    private(set) var removeParamRemoveData = [Bool]()
    var removeResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func remove(_ torrents: [MockTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        removeCallCount += 1
        removeParamTorrents.append(torrents)
        removeParamRemoveData.append(removeData)
        return removeResult
    }

    private(set) var verifyCallCount = 0
    private(set) var verifyParamTorrents = [[MockTorrent]]()
    var verifyResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func verify(_ torrents: [MockTorrent]) -> AnyPublisher<Void, Error> {
        verifyCallCount += 1
        verifyParamTorrents.append(torrents)
        return verifyResult
    }

    private(set) var setLabelCallCount = 0
    private(set) var setLabelParamLabel = [MockLabel]()
    private(set) var setLabelParamTorrents = [[MockTorrent]]()
    var setLabelResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func setLabel(_ label: MockLabel, for torrents: [MockTorrent]) -> AnyPublisher<Void, Error> {
        setLabelCallCount += 1
        setLabelParamLabel.append(label)
        setLabelParamTorrents.append(torrents)
        return setLabelResult
    }

    private(set) var updateTrackersCallCount = 0
    private(set) var updateTrackersParamTorrents = [[MockTorrent]]()
    var updateTrackersResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func updateTrackers(for torrents: [MockTorrent]) -> AnyPublisher<Void, Error> {
        updateTrackersCallCount += 1
        updateTrackersParamTorrents.append(torrents)
        return updateTrackersResult
    }

    private(set) var moveDownloadFolderCallCount = 0
    private(set) var moveDownloadFolderParamTorrents = [[MockTorrent]]()
    private(set) var moveDownloadFolderParamPath = [String]()
    var moveDownloadFolderResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    func moveDownloadFolder(for torrents: [MockTorrent], to path: String) -> AnyPublisher<Void, Error> {
        moveDownloadFolderCallCount += 1
        moveDownloadFolderParamTorrents.append(torrents)
        moveDownloadFolderParamPath.append(path)
        return moveDownloadFolderResult
    }
}

private final class MockDetailViewModel: ViewModel {
    let view = TorrentDetailViewRepresentation(
        hash: "",
        sections: Just([]).eraseToAnyPublisher(),
        isRefreshing: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()
    func receive(_ event: TorrentDetailViewEvent) {}
}
