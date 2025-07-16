# Magnesium Test Suite

This document provides an overview of the Magnesium test suite structure, conventions, and best practices.

## Overview

The Magnesium test suite is designed to provide comprehensive coverage of the application's core functionality, ensuring code quality, reliability, and maintainability. The tests are organized using Swift Testing framework and follow established patterns for clarity and consistency.

## Test Organization

### Directory Structure

```
Tests/
├── README.md                           # This documentation
├── MagnesiumTests.swift               # Main test entry point
├── AppPreferencesTests.swift          # Preferences management tests
├── ErrorHandlingTests.swift           # Error handling and edge cases
├── FormattersTests.swift              # Data formatting utilities
├── ServerTests.swift                  # Server model tests
├── SessionTests.swift                 # Session management tests
├── StandardTorrentTests.swift         # Core torrent model tests
├── TorrentManagerTests.swift          # Business logic tests
├── TorrentMapperTests.swift           # Filtering and sorting tests
├── TorrentStateTests.swift            # Torrent state enum tests
├── Mocks/                             # Mock implementations
│   ├── MockAppPreferences.swift       # Mock preferences
│   ├── MockKeychain.swift             # Mock secure storage
│   ├── MockSession.swift              # Mock session management
│   ├── MockTimer.swift                # Mock timer for testing
│   └── MockTorrentClientActing.swift  # Mock torrent client
├── Performance/                       # Performance tests
│   ├── TorrentManagerPerformanceTests.swift
│   └── TorrentMapperPerformanceTests.swift
└── Utilities/                         # Test utilities
    ├── TestDataFactory.swift          # Factory for test data
    └── TestUtilities.swift            # Common test helpers
```

### Test Categories

#### 1. Model Tests
Tests for core data models and their behavior:
- **StandardTorrentTests**: Torrent model initialization, updates, computed properties
- **TorrentStateTests**: Enum cases, localized strings, colors
- **ServerTests**: Server model encoding/decoding, equality

#### 2. Utility Tests
Tests for utility classes and helper functions:
- **TorrentMapperTests**: Filtering, sorting, and search functionality
- **FormattersTests**: Data formatting (bytes, percentages, time)

#### 3. Business Logic Tests
Tests for core application logic:
- **TorrentManagerTests**: Torrent lifecycle management, refresh operations
- **SessionTests**: Server switching, authentication, error handling
- **AppPreferencesTests**: Settings storage and retrieval

#### 4. Integration Tests
Tests for component interactions with mocked dependencies:
- Cross-component workflows
- Error propagation
- State consistency

#### 5. Performance Tests
Tests for critical path performance:
- Large dataset handling
- Memory efficiency
- Response time validation

## Test Conventions

### Naming Conventions

#### Test Files
- Format: `[ClassName]Tests.swift`
- Example: `StandardTorrentTests.swift`

#### Test Suites
- Use descriptive names with `@Suite` attribute
- Group related tests logically
- Example: `@Suite("StandardTorrent Tests")`

#### Test Methods
- Use descriptive names that explain the scenario
- Format: `@Test("Description of what is being tested")`
- Example: `@Test("StandardTorrent initialization with all properties")`

### Test Structure

#### Arrange-Act-Assert Pattern
```swift
@Test("Description of test scenario")
func testMethodName() {
    // Arrange - Set up test data and conditions
    let input = TestDataFactory.createStandardTorrent(name: "Test")
    
    // Act - Execute the code under test
    let result = input.someMethod()
    
    // Assert - Verify the expected outcome
    #expect(result == expectedValue)
}
```

#### Async Testing
```swift
@Test("Async operation test")
func asyncOperationTest() async throws {
    // Setup
    let manager = TorrentManager()
    
    // Execute async operation
    try await manager.refresh()
    
    // Verify results
    #expect(manager.torrents.count > 0)
}
```

#### Parameterized Tests
```swift
@Test("Multiple scenarios", arguments: [
    (input1, expected1),
    (input2, expected2),
    (input3, expected3)
])
func multipleScenarios(input: InputType, expected: ExpectedType) {
    let result = processInput(input)
    #expect(result == expected)
}
```

### Documentation Standards

#### Test Documentation
- Add inline comments for complex test scenarios
- Explain the purpose of non-obvious test setup
- Document expected behavior for edge cases

#### Mock Documentation
- Document mock behavior and limitations
- Explain configuration options
- Provide usage examples

## Test Data Management

### TestDataFactory
The `TestDataFactory` provides factory methods for creating test objects with sensible defaults:

```swift
// Create a standard torrent with defaults
let torrent = TestDataFactory.createStandardTorrent()

// Create with specific properties
let torrent = TestDataFactory.createStandardTorrent(
    name: "Custom Torrent",
    state: .seeding,
    progress: 1.0
)

// Create multiple torrents
let torrents = TestDataFactory.createMultipleTorrents(count: 10)
```

### Mock Objects
Mock implementations are provided for external dependencies:

- **MockTorrentClientActing**: Mock torrent client operations
- **MockKeychain**: In-memory keychain for secure storage testing
- **MockSession**: Mock session management
- **MockAppPreferences**: Mock preferences storage
- **MockTimer**: Controllable timer for time-dependent tests

## Running Tests

### Command Line
```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter "StandardTorrentTests"

# Run with coverage
swift test --enable-code-coverage
```

### Xcode
1. Open the project in Xcode
2. Use ⌘+U to run all tests
3. Use the Test Navigator to run specific tests
4. View coverage reports in the Report Navigator

## Coverage Goals

### Target Coverage Levels
- **Models**: 95%+ (critical for data integrity)
- **Utilities**: 90%+ (high-use components)
- **Business Logic**: 85%+ (complex logic paths)
- **Overall Target**: 80%+ code coverage

### Critical Paths
The following components require 90%+ coverage:
- StandardTorrent model and computed properties
- TorrentMapper filtering and sorting
- TorrentManager business logic
- Session management and error handling

## Best Practices

### Test Independence
- Each test should run independently
- Use fresh test data for each test
- Clean up resources after tests

### Error Testing
- Test both success and failure scenarios
- Verify appropriate error types are thrown
- Test error recovery behavior

### Performance Testing
- Set realistic performance expectations
- Test with representative data sizes
- Monitor memory usage in performance tests

### Maintainability
- Keep tests simple and focused
- Avoid testing implementation details
- Update tests when requirements change

## Troubleshooting

### Common Issues
1. **Flaky Tests**: Ensure tests don't depend on timing or external state
2. **Slow Tests**: Use mocks instead of real dependencies
3. **Coverage Gaps**: Review untested code paths and add targeted tests

### Debugging Tests
- Use `print()` statements for debugging test failures
- Set breakpoints in test methods
- Use Xcode's test failure debugging features

## Contributing

When adding new tests:
1. Follow the established naming conventions
2. Add appropriate documentation
3. Ensure tests are independent and reliable
4. Update this README if adding new test categories
5. Maintain the target coverage levels

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [Swift Testing Migration Guide](https://developer.apple.com/documentation/testing/migratingfromxctest)
- [Testing Best Practices](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)