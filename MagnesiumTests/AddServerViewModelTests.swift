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

    func test_select_withTransmission_shouldEmitTransmissionSelectType() {
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
