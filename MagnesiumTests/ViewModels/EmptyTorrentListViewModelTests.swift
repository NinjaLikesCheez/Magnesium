//
//  EmptyTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-01.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class EmptyTorrentListViewModelTests: XCTestCase {
    private let viewModel = EmptyTorrentListViewModel()
    private var observers = [AnyCancellable]()

    func test_showAddButton_shouldBeFalse() {
        XCTAssertFalse(viewModel.state.showAddButton)
    }

    func test_showFilterButton_shouldBeFalse() {
        XCTAssertFalse(viewModel.state.showFilterButton)
    }

    func test_refresh_shouldEmitIsLoadingFalse() {
        var values = [Bool]()
        viewModel.state.isLoading.dropFirst().sink {
            values.append($0)
        }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(values, [false])
    }

    func test_hasActiveFilters_shouldBeFalse() {
        var value: Bool?
        viewModel.state.hasActiveFilters.sink { value = $0 }.store(in: &observers)
        XCTAssertFalse(value!)
    }

    func test_filterSelected_shouldNotEmit() {
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.filterSelected(source: .view(UIView(), rect: .zero)))
        XCTAssertNil(event)
    }

    func test_settingsSelected_shouldEmitSettingsEvent() {
        var event: TorrentListEvent?
        viewModel.events.sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.settingsSelected)
        guard case .settings = event else {
            XCTFail("Unexpected event")
            return
        }
    }

    func test_addSelected_shouldNotEmitEvents() {
        var event: TorrentListEvent?
        viewModel.events.sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.addSelected(source: .view(UIView(), rect: .zero)))
        XCTAssertNil(event)
    }

    func test_itemSelected_shouldNotEmitEvents() {
        var event: TorrentListEvent?
        viewModel.events.sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.itemSelected(index: 0))
        XCTAssertNil(event)
    }

    func test_detailViewModelForItem_shouldReturnNil() {
        XCTAssertNil(viewModel.detailViewModelForItem(at: 0))
    }

    func test_contextMenuForItem_shouldReturnNil() {
        XCTAssertNil(viewModel.contextMenuForItem(at: 0))
    }
}
