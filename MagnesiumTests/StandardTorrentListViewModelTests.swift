import Combine
@testable import Magnesium
import ViewModel
import XCTest

final class StandardTorrentListViewModelTests: XCTestCase {
    private var preferences: MockPreferences!
    private var implementation: MockImplementation!
    private var viewModel: StandardTorrentListViewModel<MockImplementation>!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        preferences = MockPreferences()
        implementation = MockImplementation()
        viewModel = StandardTorrentListViewModel(
            implementation: implementation,
            server: .delugeMock(name: "Mock"),
            preferences: preferences
        )
    }

    private func getAlert(actions: () -> Void) -> Alert? {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        actions()
        guard case let .alert(alert, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return nil
        }
        return alert
    }

    // MARK: - Title

    func test_title_shouldBeExpectedTitle() {
        var title: String?
        viewModel.state.title.sink { title = $0 }.store(in: &observers)
        XCTAssertEqual(title, "Mock")
    }

    func test_title_whenEditing_shouldBeSelectionCount() {
        var title: String?
        viewModel.state.title.dropFirst().sink { title = $0 }.store(in: &observers)
        viewModel.handle(.didBeginEditing)
        XCTAssertEqual(title, "0 Selected")
    }

    func test_title_whenEditingSelectionChanged_shouldUpdate() {
        viewModel.handle(.didBeginEditing)
        var title: String?
        viewModel.state.title.dropFirst().sink { title = $0 }.store(in: &observers)
        viewModel.handle(.multiSelectUpdated(indices: [0, 1]))
        XCTAssertEqual(title, "2 Selected")
    }

    func test_title_whenEditingEnded_shouldBeDefault() {
        viewModel.handle(.didBeginEditing)
        var title: String?
        viewModel.state.title.dropFirst().sink { title = $0 }.store(in: &observers)
        viewModel.handle(.didEndEditing)
        XCTAssertEqual(title, "Mock")
    }

    // MARK: - Auto Refresh

    func test_autoRefresh_shouldFire() {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshCallCount, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.implementation.refreshCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    // MARK: - StandardTorrentListViewModelImplementation

    func test_implementation_updated_shouldUpdateItems() {
        var count = 0
        viewModel.state.items.dropFirst().sink { _ in count += 1 }.store(in: &observers)
        implementation.updatedSubject.send(([], []))
        XCTAssertEqual(count, 1)
    }

    // MARK: - Handle TorrentListViewEvent

    // MARK: refresh

    func test_refresh_shouldCallImplementationRefresh() {
        viewModel.handle(.refresh)
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_refresh_whenFails_shouldShowError() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.handle(.refresh)
        }!
        XCTAssertEqual(alert.title, "Update Failed")
    }

    func test_refresh_isLoading_shouldEmitTrueThenFalse() {
        var values = [Bool]()
        viewModel.state.isLoading.dropFirst().sink { values.append($0) }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(values, [true, false])
    }

    func test_refresh_isLoading_whenFails_shouldEmitTrueThenFalse() {
        implementation.refreshResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        var values = [Bool]()
        viewModel.state.isLoading.dropFirst().sink { values.append($0) }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(values, [true, false])
    }

    func test_refresh_withNoChanges_shouldNotEmit() {
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertNil(event)
    }

    func test_refresh_withChanges_shouldEmitTorrentsUpdatedEvent() {
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        implementation.refreshResult = Just(([MockTorrent()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)
        guard case .torrentsUpdated = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    // MARK: addSelected

    func test_addSelected_shouldEmitAddEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.addSelected(source: .view(UIView(), rect: .zero)))
        guard case .add = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_addLink_shouldCallImplementationAddLink() {
        viewModel.addLink("http://example.com")
        XCTAssertEqual(implementation.addLinkCallCount, 1)
        XCTAssertEqual(implementation.addLinkParamURL, ["http://example.com"])
    }

    func test_addLink_whenFails_shouldEmitAlert() {
        implementation.addLinkResult = Just(("ErrorTitle", "ErrorMessage")).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.addLink("http://example.com")
        }!
        XCTAssertEqual(alert.title, "ErrorTitle")
        XCTAssertEqual(alert.message, "ErrorMessage")
        XCTAssertEqual(alert.actions.map { $0.title }, ["OK"])
    }

    // MARK: filterSelected

    func test_filterSelected_shouldEmitFilterEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.filterSelected(source: .view(UIView(), rect: .zero)))
        guard case .filter = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    // MARK: itemSelected

    func test_itemSelected_shouldEmitDetailEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.itemSelected(index: 0))
        guard case .detail = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(implementation.detailViewModelCallCount, 1)
        XCTAssertEqual(implementation.detailViewModelParamTorrent.map { $0.value.name }, ["Mock"])
        XCTAssertEqual(implementation.detailViewModelParamLabels[0].value.map { $0.name }, ["", "label1", "label2"])
    }

    // MARK: settingsSelected

    func test_settingsSelected_shouldEmitSettingsEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.settingsSelected)
        guard case .settings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    // MARK: search

    func test_search_shouldUpdateItems() {
        implementation.refreshResult = Just(([
            MockTorrent(hash: "A", name: "test torrent", dateAdded: Date(timeIntervalSinceNow: 0)),
            MockTorrent(hash: "B", name: "example", dateAdded: Date(timeIntervalSinceNow: -1)),
            MockTorrent(hash: "C", name: "TEST.TORRENT", dateAdded: Date(timeIntervalSinceNow: -2)),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)
        var items: [TorrentListItem]?
        viewModel.state.items.sink { items = $0 }.store(in: &observers)
        viewModel.handle(.search(query: "test tor"))
        XCTAssertEqual(items!.count, 2)
        let names: [String?] = items?.map {
            var name: String?
            $0.name.sink { name = $0 }.store(in: &observers)
            return name
        } ?? []
        XCTAssertEqual(names, ["test torrent", "TEST.TORRENT"])
    }

    // MARK: resumeSelected

    func test_resumeSelected_shouldCallImplementationResumeAndRefresh() {
        viewModel.handle(.resumeSelected(indices: [0, 1]))
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.resumeParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_resumeSelected_whenFails_shouldEmitAlert() {
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.handle(.resumeSelected(indices: [0, 1]))
        }!
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    // MARK: pauseSelected

    func test_pauseSelected_shouldCallImplementationPauseAndRefresh() {
        viewModel.handle(.pauseSelected(indices: [0, 1]))
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.pauseParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_pauseSelected_whenFails_shouldEmitAlert() {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let alert = getAlert {
            viewModel.handle(.pauseSelected(indices: [0, 1]))
        }!
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    // MARK: removeSelected

    func test_removeSelected_withSingleTorrent_shouldEmitAlert() {
        let alert = getAlert {
            viewModel.handle(.removeSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }!
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map { $0.title }, ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_withMultipleTorrents_shouldEmitAlert() {
        let alert = getAlert {
            viewModel.handle(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "2 Torrents")
        XCTAssertEqual(alert.actions.map { $0.title }, ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_removeSelected_whenKeepDataSelected_shouldCallImplementationRemoveAndRefresh() {
        let alert = getAlert {
            viewModel.handle(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        alert.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.removeParamRemoveData, [false])
    }

    func test_removeSelected_whenKeepDataSelected_andFails_shouldEmitAlert() {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = getAlert {
            viewModel.handle(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!

        let errorAlert = getAlert {
            optionsAlert.actions.first { $0.title == "Keep Data" }?.handler?()
        }!
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    func test_removeSelected_whenRemoveDataSelected_shouldCallImplementationRemoveAndRefresh() {
        let alert = getAlert {
            viewModel.handle(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        alert.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(implementation.removeCallCount, 1)
        XCTAssertEqual(implementation.removeParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.removeParamRemoveData, [true])
    }

    func test_removeSelected_whenRemoveDataSelected_andFails_shouldEmitAlert() {
        implementation.removeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let optionsAlert = getAlert {
            viewModel.handle(.removeSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!

        let errorAlert = getAlert {
            optionsAlert.actions.first { $0.title == "Remove Data" }?.handler?()
        }!
        XCTAssertEqual(errorAlert.title, "Failed to Remove")
    }

    // MARK: moreOptionsSelected

    private func getActivities(actions: () -> Void) -> [Activity]? {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        actions()
        guard case let .activities(activities, _, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return nil
        }
        return activities
    }

    func test_moreOptionsSelected_shouldEmitExpectedActivities() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }!
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map { $0.title }, expected)
    }

    func test_moreOptionsSelected_withNoLabels_shouldEmitExpectedActivities() {
        implementation.refreshResult = Just(([MockTorrent()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }!
        let expected = ["Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities.map { $0.title }, expected)
    }

    // MARK: moreOptionsSelected - Set Label

    func test_setLabelActivity_withSingleTorrent_shouldEmitSelectionAlert() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0], source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        XCTAssertEqual(alert.title, "Set Label")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map { $0.title }, ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_withMultipleTorrents_shouldEmitSelectionAlert() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        XCTAssertEqual(alert.title, "Set Label")
        XCTAssertEqual(alert.message, "2 Torrents")
        XCTAssertEqual(alert.actions.map { $0.title }, ["None", "label1", "label2", "Cancel"])
    }

    func test_setLabelActivity_whenOptionSelected_shouldCallImplementationSetLabelAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        alert.actions.first { $0.title == "label1" }?.handler?()
        XCTAssertEqual(implementation.setLabelCallCount, 1)
        XCTAssertEqual(implementation.setLabelParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.setLabelParamLabel[0].name, "label1")
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_setLabelActivity_whenOptionSelected_andFails_shouldEmitAlert() {
        implementation.setLabelResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        let optionsAlert = getAlert {
            activities.first { $0.title == "Set Label" }?.handler()
        }!
        let errorAlert = getAlert {
            optionsAlert.actions.first { $0.title == "label1" }?.handler?()
        }!
        XCTAssertEqual(errorAlert.title, "Failed to Set Label")
    }

    // MARK: moreOptionsSelected - Verify Files

    func test_verifyFilesActivity_shouldCallImplementationVerifyFilesAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        activities.first { $0.title == "Verify Files" }?.handler()
        XCTAssertEqual(implementation.verifyCallCount, 1)
        XCTAssertEqual(implementation.verifyParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_verifyFilesActivity_whenFails_shouldEmitAlert() {
        implementation.verifyResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Verify Files" }?.handler()
        }!
        XCTAssertEqual(alert.title, "Failed to Verify Files")
    }

    // MARK: moreOptionsSelected - Move Download Folder

    func test_moveDownloadFolderActivity_shouldEmitMoveDownloadFolderEvent() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case .moveDownloadFolder = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_moveDownloadFolderActivity_withSameDownloadPath_shouldHaveCurrentPath() {
        implementation.refreshResult = Just(([
            MockTorrent(downloadPath: "/downloads"),
            MockTorrent(downloadPath: "/downloads"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)

        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case let .moveDownloadFolder(path, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(path, "/downloads")
    }

    func test_moveDownloadFolderActivity_withDifferentDownloadPaths_shouldHaveNilCurrentPath() {
        implementation.refreshResult = Just(([
            MockTorrent(downloadPath: "/downloads"),
            MockTorrent(downloadPath: "/downloads2"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)

        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case let .moveDownloadFolder(path, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertNil(path)
    }

    // swiftlint:disable:next line_length
    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_shouldCallImplementationMoveDownloadFolderAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        activities.first { $0.title == "Move Download Folder" }?.handler()
        guard case let .moveDownloadFolder(_, subject) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        subject.send("/new")
        XCTAssertEqual(implementation.moveDownloadFolderCallCount, 1)
        XCTAssertEqual(implementation.moveDownloadFolderParamPath, ["/new"])
    }

    func test_moveDownloadFolderActivity_whenSubjectReceivesValue_andFails_shouldEmitAlert() {
        implementation.moveDownloadFolderResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        var event: TorrentListEvent?
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

    // MARK: moreOptionsSelected - Update Trackers

    func test_updateTrackersActivity_shouldCallImplementationUpdateTrackersAndRefresh() {
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        activities.first { $0.title == "Update Trackers" }?.handler()
        XCTAssertEqual(implementation.updateTrackersCallCount, 1)
        XCTAssertEqual(implementation.updateTrackersParamTorrents[0].map { $0.name }, ["Mock", "Mock 2"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_updateTrackersActivity_whenFails_shouldEmitAlert() {
        implementation.updateTrackersResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let activities = getActivities {
            viewModel.handle(.moreOptionsSelected(indices: [0, 1], source: .view(UIView(), rect: .zero)))
        }!
        let alert = getAlert {
            activities.first { $0.title == "Update Trackers" }?.handler()
        }!
        XCTAssertEqual(alert.title, "Failed to Update Trackers")
    }

    // MARK: - State

    // MARK: items

    func test_items_shouldEmitInitialValue() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.items.first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_items_shouldRemoveDuplicates() {
        var count = 0
        viewModel.state.items.dropFirst().sink { _ in count += 1 }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(count, 0)
    }

    func test_items_shouldEmitNewValues() {
        var count = 0
        viewModel.state.items.dropFirst().sink { _ in count += 1 }.store(in: &observers)
        implementation.refreshResult = Just(([MockTorrent()], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)
        XCTAssertEqual(count, 1)
    }

    // MARK: hasActiveFilters

    func test_hasActiveFilters_withNoFilters_shouldBeFalse() {
        var value: Bool?
        viewModel.state.hasActiveFilters.sink { value = $0 }.store(in: &observers)
        XCTAssertFalse(value!)
    }

    func test_hasActiveFilters_withFilters_shouldBeTrue() {
        var value: Bool?
        viewModel.state.hasActiveFilters.dropFirst().sink { value = $0 }.store(in: &observers)
        preferences.set(FilterOptions(state: .downloading), for: PreferenceKeys.filterOptions)
        XCTAssertTrue(value!)
    }

    // MARK: totalDownloadSpeed

    func test_totalDownloadSpeed_shouldBeSumOfAllDownloadSpeeds() {
        implementation.refreshResult = Just(([
            MockTorrent(downloadRate: 100_000, label: "label1"),
            MockTorrent(downloadRate: 200_000, label: "label2"),
            MockTorrent(downloadRate: 400_000, label: "label1"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)
        preferences.set(FilterOptions(label: "label2"), for: PreferenceKeys.filterOptions)

        var value: String?
        viewModel.state.totalDownloadSpeed.first().sink { value = $0 }.store(in: &observers)
        XCTAssertEqual(value, "↓ 684 KB/s")
    }

    // MARK: totalUploadSpeed

    func test_totalUploadSpeed_shouldBeSumOfAllDownloadSpeeds() {
        implementation.refreshResult = Just(([
            MockTorrent(uploadRate: 100_000, label: "label1"),
            MockTorrent(uploadRate: 200_000, label: "label2"),
            MockTorrent(uploadRate: 400_000, label: "label1"),
        ], [])).setFailureType(to: Error.self).eraseToAnyPublisher()
        viewModel.handle(.refresh)
        preferences.set(FilterOptions(label: "label2"), for: PreferenceKeys.filterOptions)

        var value: String?
        viewModel.state.totalUploadSpeed.first().sink { value = $0 }.store(in: &observers)
        XCTAssertEqual(value, "↑ 684 KB/s")
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
        viewModel.handle(.refresh)

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
        // swiftformat:disable all
        let expected = """

              Pause
              Verify Files
              Move Download Folder
              Update Trackers
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable all
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
        // swiftformat:disable all
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
        // swiftformat:enable all
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_contextMenuForItem_withInactiveTorrent_shouldReturnExpectedMenu() {
        implementation.refreshResult = Just((
            [MockTorrent(standardState: .paused)],
            [MockLabel(name: ""), MockLabel(name: "label1"), MockLabel(name: "label2")]
        ))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.handle(.refresh)

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
        // swiftformat:disable all
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
        // swiftformat:enable all
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsActive_shouldReturnedExpectedConfiguration() {
        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        XCTAssertEqual(config?.actions.map { $0.image }, [UIImage(systemName: "pause.fill")])
        XCTAssertEqual(config?.actions.map { $0.backgroundColor }, [.systemBlue])
        XCTAssertEqual(config?.actions.map { $0.style }, [.normal])
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsInactive_shouldReturnedExpectedConfiguration() {
        implementation.refreshResult = Just(([MockTorrent(standardState: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.handle(.refresh)

        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        XCTAssertEqual(config?.actions.map { $0.image }, [UIImage(systemName: "play.fill")])
        XCTAssertEqual(config?.actions.map { $0.backgroundColor }, [.systemBlue])
        XCTAssertEqual(config?.actions.map { $0.style }, [.normal])
    }

    func test_pauseSwipeAction_shouldCallImplementationPauseAndRefresh() {
        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        config?.actions[0].handler()
        XCTAssertEqual(implementation.pauseCallCount, 1)
        XCTAssertEqual(implementation.pauseParamTorrents[0].map { $0.name }, ["Mock"])
        XCTAssertEqual(implementation.refreshCallCount, 2)
    }

    func test_pauseSwipeAction_whenFails_shouldEmitAlert() {
        implementation.pauseResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let alert = getAlert {
            config?.actions[0].handler()
        }!
        XCTAssertEqual(alert.title, "Failed to Pause")
    }

    func test_resumeSwipeAction_shouldCallImplementationResumeAndRefresh() {
        implementation.refreshResult = Just(([MockTorrent(name: "Mock", standardState: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.handle(.refresh)

        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        config?.actions[0].handler()
        XCTAssertEqual(implementation.resumeCallCount, 1)
        XCTAssertEqual(implementation.resumeParamTorrents[0].map { $0.name }, ["Mock"])
        XCTAssertEqual(implementation.refreshCallCount, 3)
    }

    func test_resumeSwipeAction_whenFails_shouldEmitAlert() {
        implementation.refreshResult = Just(([MockTorrent(name: "Mock", standardState: .paused)], []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        viewModel.handle(.refresh)
        implementation.resumeResult = Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()

        let config = viewModel.leadingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let alert = getAlert {
            config?.actions[0].handler()
        }!
        XCTAssertEqual(alert.title, "Failed to Resume")
    }

    func test_trailingSwipeActionsConfiguration_shouldReturnExpectedConfiguration() {
        let config = viewModel.trailingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let expected = [UIImage(systemName: "trash.fill"), UIImage(systemName: "ellipsis.circle.fill")]
        XCTAssertEqual(config?.actions.map { $0.image }, expected)
        XCTAssertEqual(config?.actions.map { $0.backgroundColor }, [nil, .systemGray])
        XCTAssertEqual(config?.actions.map { $0.style }, [.destructive, .normal])
    }

    func test_moreSwipeAction_shouldEmitActivities() {
        let config = viewModel.trailingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let activities = getActivities {
            config?.actions[1].handler()
        }
        let expected = ["Set Label", "Verify Files", "Move Download Folder", "Update Trackers"]
        XCTAssertEqual(activities?.map { $0.title }, expected)
    }

    func test_removeSwipeAction_shouldCallImplementationRemoveAndRefresh() {
        let config = viewModel.trailingSwipeActionsConfigurationForItem(at: 0, source: .view(UIView(), rect: .zero))
        let alert = getAlert {
            config?.actions[0].handler()
        }!
        XCTAssertEqual(alert.title, "Remove")
        XCTAssertEqual(alert.message, "Mock")
        XCTAssertEqual(alert.actions.map { $0.title }, ["Keep Data", "Remove Data", "Cancel"])
    }
}

// MARK: - Mocks

private final class MockImplementation: StandardTorrentListViewModelImplementation {
    typealias Torrent = MockTorrent
    typealias Label = MockLabel

    let updatedSubject = PassthroughSubject<([MockTorrent], [MockLabel]), Never>()

    var updated: AnyPublisher<([MockTorrent], [MockLabel]), Never> {
        return updatedSubject.eraseToAnyPublisher()
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
    var detailViewModelResult = AnyEmitterViewModel(MockDetailViewModel())
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

private final class MockDetailViewModel: ViewModel, EventEmitter {
    let state = TorrentDetailViewState(
        hash: "",
        sections: Just([]).eraseToAnyPublisher(),
        isRefreshing: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailEvent, Never> = Empty().eraseToAnyPublisher()
    func handle(_ event: TorrentDetailViewEvent) {}
}
