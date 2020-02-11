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

    func test_types() {
        XCTAssertEqual(viewModel.state.types, ["Deluge", "Transmission"])
    }

    func test_select_withDeluge_shouldEmitDelugeSelectType() {
        var event: AddServerEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.selectType(index: 0))
        guard case let .add(type) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, ServerType.deluge)
    }

    func test_select_withTransmission_shouldEmitTransmissionSelectType() {
        var event: AddServerEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.selectType(index: 1))
        guard case let .add(type) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, ServerType.transmission)
    }
}
