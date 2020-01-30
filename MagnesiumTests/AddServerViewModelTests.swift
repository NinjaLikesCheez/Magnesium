//
//  AddServerViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-29.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class AddServerViewModelTests: XCTestCase {
    private var observers = [AnyCancellable]()
    private let viewModel = AddServerViewModel()

    func testTypes() {
        XCTAssertEqual(viewModel.state.types, ["Deluge", "Transmission"])
    }

    func testSelectDelugeEvent() {
        var type: ServerType!
        viewModel.events.first().sink {
            guard case let .add(inner) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            type = inner
        }.store(in: &observers)
        viewModel.handle(.selectType(index: 0))
        XCTAssertEqual(type, ServerType.deluge)
    }

    func testSelectTransmissionEvent() {
        var type: ServerType!
        viewModel.events.first().sink {
            guard case let .add(inner) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            type = inner
        }.store(in: &observers)
        viewModel.handle(.selectType(index: 1))
        XCTAssertEqual(type, ServerType.transmission)
    }
}
