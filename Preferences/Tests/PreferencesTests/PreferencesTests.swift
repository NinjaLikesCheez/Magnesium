import Combine
@testable import Preferences
import XCTest

class UserDefaultPreferencesTests: XCTestCase {
    private let preferenceManager = UserDefaultsPreferences()
    private let key = PreferenceKey<String>("_test", defaultValue: "Default")
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        preferenceManager.removeValue(for: key)
    }

    override func tearDown() {
        super.tearDown()
        preferenceManager.removeValue(for: key)
    }

    func test_value_shouldReturnDefault() throws {
        XCTAssertEqual(try preferenceManager.value(for: key), "Default")
    }

    func test_set_shouldPersistValue() throws {
        try preferenceManager.set("Value", for: key)
        XCTAssertEqual(try preferenceManager.value(for: key), "Value")
        let newPreferenceManager = UserDefaultsPreferences()
        XCTAssertEqual(try newPreferenceManager.value(for: key), "Value")
    }

    func test_preferenceChanged_whenPreferenceChanged_shouldEmitNewValue() throws {
        let expectation = self.expectation(description: "Value received")
        preferenceManager.preferenceChanged.first().sink { change in
            XCTAssertEqual(change.key.value, self.key.value)
            if case let .updated(value) = change.type {
                XCTAssertEqual(value as? String, "Value")
            } else {
                XCTFail("Expected change")
            }
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

    func test_valueUpdatedPublisher_whenValueRemoved_shouldEmitCompletion() throws {
        let expectation = self.expectation(description: "Value received")
        preferenceManager.valueUpdatedPublisher(for: key)
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { _ in })
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

    func test_valuePublisher_shouldEmitNewValues() throws {
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
        XCTAssertEqual(try preferenceManager.value(for: key), "Default")
    }

    func test_set_withCodable_shouldPersist() throws {
        let key = PreferenceKey<MockCodable>(self.key.value, defaultValue: MockCodable(name: ""))
        try preferenceManager.set(MockCodable(name: "Codable"), for: key)
        XCTAssertEqual(try preferenceManager.value(for: key).name, "Codable")
    }
}

private struct MockCodable: Codable {
    let name: String
}
