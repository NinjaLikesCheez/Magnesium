import Combine
@testable import Preferences
import XCTest

class UserDefaultPreferencesTests: XCTestCase {
    private let preferenceManager = UserDefaultsPreferences()
    private let key = PreferenceKey<String>("_test")
    private let keyWithDefault = PreferenceKey<String>("_testDefault")
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        preferenceManager.removeValue(for: key)
    }

    override func tearDown() {
        super.tearDown()
        preferenceManager.removeValue(for: key)
    }

    func test_registerDefault_shouldRegisterDefaultValue() throws {
        try preferenceManager.registerDefault("Value", for: keyWithDefault)
        XCTAssertEqual(try preferenceManager.value(for: keyWithDefault), "Value")
    }

    func tests_registerDefault_withCodable_shouldRegisterDefaultValue() throws {
        let keyWithDefault = PreferenceKey<MockCodable>(self.keyWithDefault.value)
        try preferenceManager.registerDefault(MockCodable(name: "Codable"), for: keyWithDefault)
        XCTAssertEqual(try preferenceManager.value(for: keyWithDefault)?.name, "Codable")
    }

    func test_set_shouldPersistValue() throws {
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        let newPreferenceManager = UserDefaultsPreferences()
        XCTAssertEqual(try newPreferenceManager.value(for: key), "Value")
    }

    func test_valueUpdated_whenValueChanged_shouldEmitNewValue() throws {
        let expectation = self.expectation(description: "Value received")
        preferenceManager.valueUpdated.sink { anyKey, value in
            XCTAssertEqual(anyKey.value, self.key.value)
            XCTAssertEqual(value as? String, "Value")
            expectation.fulfill()
        }.store(in: &observers)
        try preferenceManager.set("Value", for: key)
        waitForExpectations(timeout: 0)
    }

    func test_valueUpdatedPublisher_whenValueChanged_shouldEmitNewValue() throws {
        let expectation = self.expectation(description: "Value received")
        preferenceManager.valueUpdatedPublisher(for: key).sink { value in
            XCTAssertEqual(value, "Value")
            expectation.fulfill()
        }.store(in: &observers)
        try preferenceManager.set("Value", for: key)
        waitForExpectations(timeout: 0)
    }

    func test_valueUpdatedPublisher_whenValueRemoved_shouldEmitNil() throws {
        let expectation = self.expectation(description: "Value received")
        preferenceManager.valueUpdatedPublisher(for: key)
            .sink { value in
                XCTAssertNil(value)
                expectation.fulfill()
            }
            .store(in: &observers)
        preferenceManager.removeValue(for: key)
        waitForExpectations(timeout: 0)
    }

    func test_valuePublisher_shouldEmitInitialValue() throws {
        try preferenceManager.set("Value", for: key)
        let expectation = self.expectation(description: "Value received")
        preferenceManager.valuePublisher(for: key).first().sink { value in
            XCTAssertEqual(value, "Value")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_valuePublisher_shouldEmitNewValues() {
        let expectation = self.expectation(description: "Value received")
        preferenceManager.valuePublisher(for: key).dropFirst().first().sink { value in
            XCTAssertEqual(value, "New")
            expectation.fulfill()
        }.store(in: &observers)
        try preferenceManager.set("New", for: key)
        waitForExpectations(timeout: 0)
    }

    func test_containsValue() throws {
        XCTAssertFalse(preferenceManager.containsValue(for: key))
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        XCTAssertTrue(preferenceManager.containsValue(for: key))
    }

    func test_removeValue() throws {
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        preferenceManager.removeValue(for: key)
        XCTAssertNil(try preferenceManager.value(for: key))
    }

    func test_set_withCodable_shouldPersist() throws {
        let key = PreferenceKey<MockCodable>(self.key.value)
        try preferenceManager.set(MockCodable(name: "Codable"), for: key)
        XCTAssertEqual(try preferenceManager.value(for: key)?.name, "Codable")
    }
}

private struct MockCodable: Codable {
    let name: String
}
