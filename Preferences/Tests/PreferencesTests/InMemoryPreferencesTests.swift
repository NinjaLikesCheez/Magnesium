import Combine
@testable import Preferences
import XCTest

class InMemoryPreferencesTests: XCTestCase {
    private let key = PreferenceKey<String>("_test", defaultValue: "Default")
    private var preferences: InMemoryPreferences!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        preferences = InMemoryPreferences()
        cancellables = Set()
        preferences.reset()
    }

    override func tearDown() {
        super.tearDown()
        preferences.reset()
    }

    func test_value_shouldReturnDefault() {
        XCTAssertEqual(preferences.value(for: key), "Default")
    }

    func test_value_withCodable_shouldReturnDefault() {
        let key = PreferenceKey<MockCodable>(self.key.value, defaultValue: MockCodable(name: "name"))
        XCTAssertEqual(preferences.value(for: key).name, "name")
    }

    func test_preferencesChanged_whenPreferenceUpdated_shouldEmitUpdate() {
        let expectation = self.expectation(description: "Value received")
        preferences.preferencesChanged.first().sink { change in
            XCTAssertTrue(change.isRelevant(to: self.key))
            if case let .updated(_, value) = change {
                XCTAssertEqual(value as? String, "Value")
            } else {
                XCTFail("Unexpected change")
            }
            expectation.fulfill()
        }.store(in: &cancellables)
        preferences.set("Value", for: key)
        waitForExpectations(timeout: 0)
    }

    func test_preferencesChanged_whenPreferenceRemoved_shouldEmitDeleted() {
        preferences.set("Value", for: key)
        let expectation = self.expectation(description: "Value received")
        preferences.preferencesChanged.first().sink { change in
            XCTAssertTrue(change.isRelevant(to: self.key))
            defer { expectation.fulfill() }
            guard case .deleted = change else {
                XCTFail("Unexpected change")
                return
            }
        }.store(in: &cancellables)
        preferences.removeValue(for: key)
        waitForExpectations(timeout: 0)
    }

    func test_preferencesChanged_whenPreferencesReset_shouldEmitReset() {
        let expectation = self.expectation(description: "Value received")
        preferences.preferencesChanged.first().sink { change in
            XCTAssertTrue(change.isRelevant(to: self.key))
            defer { expectation.fulfill() }
            guard case .reset = change else {
                XCTFail("Unexpected change")
                return
            }
        }.store(in: &cancellables)
        preferences.reset()
        waitForExpectations(timeout: 0)
    }

    func test_valueUpdatedPublisher_whenValueChanged_shouldEmitNewValue() {
        let expectation = self.expectation(description: "Value received")
        preferences.valueUpdatedPublisher(for: key).first().sink { value in
            XCTAssertEqual(value, "Value")
            expectation.fulfill()
        }.store(in: &cancellables)
        preferences.set("Value", for: key)
        waitForExpectations(timeout: 0)
    }

    func test_valueUpdatedPublisher_whenPreferencesReset_shouldEmitDefaultValue() {
        preferences.set("Value", for: key)
        let expectation = self.expectation(description: "Value received")
        preferences.valueUpdatedPublisher(for: key).first().sink { value in
            XCTAssertEqual(value, "Default")
            expectation.fulfill()
        }.store(in: &cancellables)
        preferences.reset()
        waitForExpectations(timeout: 0)
    }

    func test_valueUpdatedPublisher_whenValueRemoved_shouldEmitCompletion() {
        let expectation = self.expectation(description: "Value received")
        preferences.valueUpdatedPublisher(for: key)
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        preferences.removeValue(for: key)
        waitForExpectations(timeout: 0)
    }

    func test_valuePublisher_shouldEmitInitialValue() {
        preferences.set("Value", for: key)
        let expectation = self.expectation(description: "Value received")
        preferences.valuePublisher(for: key).first().sink { value in
            XCTAssertEqual(value, "Value")
            expectation.fulfill()
        }.store(in: &cancellables)
        waitForExpectations(timeout: 0)
    }

    func test_valuePublisher_shouldEmitNewValues() {
        let expectation = self.expectation(description: "Value received")
        preferences.valuePublisher(for: key).dropFirst().first().sink { value in
            XCTAssertEqual(value, "New")
            expectation.fulfill()
        }.store(in: &cancellables)
        preferences.set("New", for: key)
        waitForExpectations(timeout: 0)
    }

    func test_containsValue() {
        XCTAssertFalse(preferences.containsValue(for: key))
        preferences.set("Value", for: key)
        XCTAssertEqual(preferences.value(for: key), "Value")
        XCTAssertTrue(preferences.containsValue(for: key))
    }

    func test_removeValue() {
        preferences.set("Value", for: key)
        XCTAssertEqual(preferences.value(for: key), "Value")
        preferences.removeValue(for: key)
        XCTAssertEqual(preferences.value(for: key), "Default")
    }

    func test_set_withCodable_shouldBeStored() {
        let key = PreferenceKey<MockCodable>(self.key.value, defaultValue: MockCodable(name: ""))
        preferences.set(MockCodable(name: "Codable"), for: key)
        XCTAssertEqual(preferences.value(for: key).name, "Codable")
    }
}

private struct MockCodable: Codable {
    let name: String
}
