//
//  DefaultSessionTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import Preferences
import XCTest

class DefaultSessionTests: XCTestCase {
    let session: Session = DefaultSession(preferences: MockPreferences())

    func testServerSubjectHasInitialValue() {
        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .sink { _ in
                expectation.fulfill()
            }
        _ = observer
        waitForExpectations(timeout: 1)
    }

    func testServerSubjectEmitsValueOnChange() {
        let server = Server(name: "Server", type: .deluge, data: Data())

        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .dropFirst()
            .sink { new in
                XCTAssertEqual(server.id, new?.id)
                expectation.fulfill()
            }
        _ = observer

        session.server = server

        waitForExpectations(timeout: 1)
    }
}
