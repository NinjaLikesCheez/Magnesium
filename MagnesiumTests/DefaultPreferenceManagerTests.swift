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
    private let keyWithDefault = PreferenceKey<String>("_testDefault")

    override func setUp() {
        preferenceManager.removeValue(for: key)
    }

    override func tearDown() {
        preferenceManager.removeValue(for: key)
    }

    func testRegisterDefaults() throws {
        try preferenceManager.registerDefault("Value", for: keyWithDefault)
        XCTAssertEqual(try preferenceManager.value(for: keyWithDefault), "Value")
    }

    func testRegisterDefaultsCodable() throws {
        let keyWithDefault = PreferenceKey<DummyCodable>(self.keyWithDefault.value)
        try preferenceManager.registerDefault(DummyCodable(name: "Codable"), for: keyWithDefault)
        XCTAssertEqual(try preferenceManager.value(for: keyWithDefault)?.name, "Codable")
    }

    func testPersistance() throws {
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        let newPreferenceManager = DefaultPreferenceManager()
        XCTAssertEqual(try newPreferenceManager.value(for: key), "Value")
    }

    func testValueUpdated() throws {
        let key = PreferenceKey<String>("_test")

        let expectation = self.expectation(description: "Value received")
        let observer = preferenceManager.valueUpdated.sink { args in
            let (anyKey, value) = args
            XCTAssertEqual(anyKey.value, key.value)
            XCTAssertEqual(value as? String, "Value")
            expectation.fulfill()
        }
        _ = observer

        try preferenceManager.set("Value", for: key)

        wait(for: [expectation], timeout: 1)
    }

    func testContainsValue() throws {
        let key = PreferenceKey<String>("_test")
        XCTAssertFalse(preferenceManager.containsValue(for: key))
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        XCTAssertTrue(preferenceManager.containsValue(for: key))
    }

    func testRemoveValue() throws {
        let key = PreferenceKey<String>("_test")
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        preferenceManager.removeValue(for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), nil)
    }

    func testCodable() throws {
        let key = PreferenceKey<DummyCodable>(self.key.value)
        try preferenceManager.set(DummyCodable(name: "Codable"), for: key)
        XCTAssertEqual(try preferenceManager.value(for: key)?.name, "Codable")
    }
}

private struct DummyCodable: Codable {
    let name: String
}
