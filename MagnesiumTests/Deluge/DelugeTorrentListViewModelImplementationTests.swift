//
//  DelugeTorrentListViewModelImplementationTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class DelugeTorrentListViewModelImplementationTests: XCTestCase {
    private var client: MockDelugeClient!
    private var preferences: MockPreferences!
    private var implementation: DelugeTorrentListViewModelImplementation!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        preferences = MockPreferences()
        implementation = DelugeTorrentListViewModelImplementation(client: client, preferences: preferences)
    }

    func test_refresh_shouldGetCurrentState() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(client.getCurrentStateCallCount, 1)
    }

    func test_detailViewModel_shouldReturnExpectedViewModelType() {
        let viewModel = implementation.detailViewModel(
            for: CurrentValueSubject(.mock()),
            labels: CurrentValueSubject([])
        ).base as AnyObject
        let expectedType = StandardTorrentDetailViewModel<DelugeTorrentDetailViewModelImplementation>.self
        guard type(of: viewModel) === expectedType else {
            XCTFail("Unexpected type: \(type(of: viewModel))")
            return
        }
    }

    func test_addLink_withInvalidURL_shouldReturnError() {
        var error: (String, String)?
        implementation.addLink("^").sink { error = $0 }.store(in: &observers)
        XCTAssertEqual(error?.0, "Unable to Add Link")
        XCTAssertEqual(error?.1, "That link doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldAddMagnetURL() {
        implementation.addLink("magnet:?").sink { _ in }.store(in: &observers)
        XCTAssertEqual(client.addMagnetURLCallCount, 1)
        XCTAssertEqual(client.addMagnetURLParamMagnetURL, [URL(string: "magnet:?")!])
    }

    func test_addLink_withMagnetLink_whenFails_shouldReturnError() {
        client.addMagnetURLResult = Fail(error: .unauthenticated).eraseToAnyPublisher()
        var error: (String, String)?
        implementation.addLink("magnet:?").sink { error = $0 }.store(in: &observers)
        XCTAssertEqual(error?.0, "Failed to Add Torrent")
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        implementation.addLink("http://example.com").sink { _ in }.store(in: &observers)
        XCTAssertEqual(client.addURLCallCount, 1)
        XCTAssertEqual(client.addURLParamURL, [URL(string: "http://example.com")!])
    }

    func test_addLink_withRegularLink_whenFails_shouldReturnError() {
        client.addURLResult = Fail(error: .unauthenticated).eraseToAnyPublisher()
        var error: (String, String)?
        implementation.addLink("http://example.com").sink { error = $0 }.store(in: &observers)
        XCTAssertEqual(error?.0, "Failed to Add Torrent")
    }

    func test_pause_shouldPause() {
        implementation.pause([.randomMock(), .randomMock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.pauseCallCount, 1)
    }

    func test_resume_shouldResume() {
        implementation.resume([.randomMock(), .randomMock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.resumeCallCount, 1)
    }

    func test_remove_withKeepData_shouldRemove() {
        implementation.remove([.randomMock(), .randomMock()], removeData: false)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.removeCallCount, 1)
        XCTAssertEqual(client.removeParamRemoveData, [false])
    }

    func test_remove_withRemoveData_shouldRemove() {
        implementation.remove([.randomMock(), .randomMock()], removeData: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.removeCallCount, 1)
        XCTAssertEqual(client.removeParamRemoveData, [true])
    }

    func test_verify_shouldRecheck() {
        implementation.verify([.randomMock(), .randomMock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.recheckCallCount, 1)
    }

    func test_setLabel_shouldSetLabels() {
        implementation.setLabel(.mock(name: "label1"), for: [.randomMock(), .randomMock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.setLabelCallCount, 2)
        XCTAssertEqual(client.setLabelParamLabel, ["label1", "label1"])
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: [.randomMock(), .randomMock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.reannounceCallCount, 1)
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        implementation.moveDownloadFolder(for: [.randomMock(), .randomMock()], to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.moveStorageCallCount, 1)
        XCTAssertEqual(client.moveStorageParamPath, ["/new"])
    }

    func test_refreshDeluge_shouldGetCurrentState() {
        implementation.refreshDeluge().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(client.getCurrentStateCallCount, 1)
    }

    func test_refreshDeluge_shouldEmitUpdate() {
        let expectation = self.expectation(description: "Value received")
        implementation.updated.sink { _ in expectation.fulfill() }.store(in: &observers)
        implementation.refreshDeluge().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        waitForExpectations(timeout: 0)
    }
}
