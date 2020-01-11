//
//  DefaultPreferenceManagerTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-11.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

class DefaultPreferenceManagerTests: XCTestCase {
    private let preferenceManager = DefaultPreferenceManager()
    private let key = PreferenceKey<String>("_test")

    override func setUp() {
        preferenceManager.removeValue(for: key)
    }

    override func tearDown() {
        preferenceManager.removeValue(for: key)
    }

    func testPersistance() {
        preferenceManager.set("Value", for: key)
        XCTAssertEqual(preferenceManager.value(for: key), "Value")
        let newPreferenceManager = DefaultPreferenceManager()
        XCTAssertEqual(newPreferenceManager.value(for: key), "Value")
    }

    func testValueUpdated() {
        let key = PreferenceKey<String>("_test")

        let expectation = self.expectation(description: "Value received")
        let observer = preferenceManager.valueUpdated.sink { args in
            let (anyKey, value) = args
            XCTAssertEqual(anyKey.value, key.value)
            XCTAssertEqual(value as! String, "Value")
            expectation.fulfill()
        }
        _ = observer

        preferenceManager.set("Value", for: key)
        
        wait(for: [expectation], timeout: 1)
    }

    func testContainsValue() {
        let key = PreferenceKey<String>("_test")
        XCTAssertFalse(preferenceManager.containsValue(for: key))
        preferenceManager.set("Value", for: key)
        XCTAssertEqual(preferenceManager.value(for: key), "Value")
        XCTAssertTrue(preferenceManager.containsValue(for: key))
    }

    func testRemoveValue() {
        let key = PreferenceKey<String>("_test")
        preferenceManager.set("Value", for: key)
        XCTAssertEqual(preferenceManager.value(for: key), "Value")
        preferenceManager.removeValue(for: key)
        XCTAssertEqual(preferenceManager.value(for: key), nil)
    }

    func testCodable() {
        struct MockCodable: Codable {
            let name: String
        }

        let key = PreferenceKey<MockCodable>(self.key.value)
        preferenceManager.set(MockCodable(name: "Codable"), for: key)
        XCTAssertEqual(preferenceManager.value(for: key)?.name, "Codable")
    }
}
