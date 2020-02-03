//
//  DelugeTorrentDetailFileViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class DelugeTorrentDetailFileViewModelTests: XCTestCase {
    private let subject = CurrentValueSubject<DelugeTorrentFile, Never>(.mock(
        index: 0,
        name: "file.rar",
        progress: 0.189838
    ))
    private lazy var viewModel = StandardTorrentDetailFileViewModel(subject: subject)
    private var observers = [AnyCancellable]()

    func test_id_shouldBeEqualToIndex() {
        var file = subject.value
        XCTAssertEqual(StandardTorrentDetailFileViewModel(subject: CurrentValueSubject(file)).id, viewModel.id)
        file.index = 1
        XCTAssertNotEqual(StandardTorrentDetailFileViewModel(subject: CurrentValueSubject(file)).id, viewModel.id)
    }

    func test_name() {
        var value: String?
        viewModel.state.name.sink { value = $0 }.store(in: &observers)
        XCTAssertEqual(value, "file.rar")
    }

    func test_progress() {
        var value: String?
        viewModel.state.progress.sink { value = $0 }.store(in: &observers)
        XCTAssertEqual(value, "19%")
    }
}
