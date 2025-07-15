# Unit Testing Plan Design Document

## Overview

This design outlines a comprehensive unit testing strategy for the Magnesium torrent client application. The approach follows Swift testing best practices, emphasizing testability, maintainability, and comprehensive coverage of critical business logic. The design prioritizes testing core models, utilities, and business logic while establishing patterns for mocking external dependencies.

## Architecture

### Testing Framework
- **Primary Framework**: Swift Testing (modern Swift testing framework)
- **Test Target**: `MagnesiumTests` (already exists but currently minimal)
- **Organization**: Mirror source structure in test directory for easy navigation
- **Naming Convention**: `[ClassName]Tests.swift` for test files
- **Import**: `import Testing` instead of `import XCTest`

### Test Categories
1. **Model Tests**: Data models, enums, and their computed properties
2. **Utility Tests**: Formatters, mappers, and helper functions  
3. **Business Logic Tests**: Core application logic and state management
4. **Integration Tests**: Component interactions with mocked dependencies
5. **Performance Tests**: Critical path performance validation

### Dependency Management
- **Mocking Strategy**: Protocol-based mocking for external dependencies
- **Test Doubles**: In-memory implementations for keychain, preferences, and network
- **Isolation**: Each test runs in isolation with fresh state

## Components and Interfaces

### Core Model Testing

#### StandardTorrent Tests
```swift
@Suite("StandardTorrent Tests")
struct StandardTorrentTests {
    // Test initialization, updates, computed properties
    // Focus on ratio calculations, state-dependent properties
    // Equality and hashing behavior
}
```

**Key Test Areas:**
- Property initialization and validation
- Update method behavior
- Computed properties (ratio, isActive, localizedSpeed, etc.)
- Equality and hashing consistency
- Edge cases (infinite ratios, zero values)

#### TorrentState Tests
```swift
@Suite("TorrentState Tests")
struct TorrentStateTests {
    // Test enum cases, localized strings, colors
    // Codable conformance
}
```

### Utility Testing

#### TorrentMapper Tests
```swift
@Suite("TorrentMapper Tests")
struct TorrentMapperTests {
    // Test filtering by state, labels, search query
    // Test sorting by different criteria
    // Test combined operations
    // Performance tests for large datasets
}
```

**Critical Test Scenarios:**
- Filter combinations (multiple states, labels)
- Search functionality with special characters
- Sort stability and correctness
- Empty and edge case handling

#### Formatters Tests
```swift
@Suite("Formatters Tests")
struct FormattersTests {
    // Test byte formatting, percentage formatting
    // Test ETA formatting, number formatting
    // Test locale-specific behavior
}
```

### Business Logic Testing

#### AppPreferences Tests
```swift
@Suite("AppPreferences Tests")
struct AppPreferencesTests {
    // Test server management operations
    // Test preference persistence and retrieval
    // Test reset functionality
    // Mock keychain interactions
}
```

#### Session Tests
```swift
@Suite("Session Tests")
struct SessionTests {
    // Test server switching logic
    // Test action implementation creation
    // Test error handling scenarios
    // Mock external dependencies
}
```

#### TorrentManager Tests
```swift
@Suite("TorrentManager Tests")
struct TorrentManagerTests {
    // Test torrent refresh and delta updates
    // Test filtering and search operations
    // Test action delegation
    // Mock session and preferences
}
```

## Data Models

### Test Data Factories
```swift
struct TestDataFactory {
    static func createStandardTorrent(
        name: String = "Test Torrent",
        state: TorrentState = .downloading,
        progress: Float = 0.5
        // ... other parameters with defaults
    ) -> StandardTorrent
    
    static func createServer(
        name: String = "Test Server",
        type: ServerType = .deluge
    ) -> Server
    
    static func createMultipleTorrents(count: Int) -> [StandardTorrent]
}
```

### Mock Implementations
```swift
class MockTorrentClientActing: TorrentClientActing {
    var refreshResult: ([StandardTorrent], [StandardLabel]) = ([], [])
    var refreshError: Error?
    var refreshCallCount = 0
    
    func refresh() async throws -> ([StandardTorrent], [StandardLabel]) {
        refreshCallCount += 1
        if let error = refreshError { throw error }
        return refreshResult
    }
    // ... other methods
}

class MockKeychain: Keychain {
    private var storage: [String: Data] = [:]
    var changeSubject = PassthroughSubject<KeychainChange, Never>()
    
    var changePublisher: AnyPublisher<KeychainChange, Never> {
        changeSubject.eraseToAnyPublisher()
    }
    // ... implementation
}
```

## Error Handling

### Error Testing Strategy
- **Expected Errors**: Test proper error throwing and handling
- **Edge Cases**: Invalid data, network failures, missing dependencies
- **Error Recovery**: Test system behavior after error conditions
- **Error Messages**: Validate error descriptions and user-facing messages

### Test Error Scenarios
```swift
@Test("Session throws error for missing keychain data")
func sessionThrowsErrorForMissingKeychainData() async {
    let server = TestDataFactory.createServer()
    let session = Session()
    
    await #expect(throws: Session.Error.self) {
        try session.setServer(server)
    } errorHandler: { error in
        if case .missingKeychainData(let errorServer) = error {
            #expect(errorServer == server)
        } else {
            Issue.record("Expected missingKeychainData error")
        }
    }
}
```

## Testing Strategy

### Test Organization
```
Tests/
├── MagnesiumTests/
│   ├── Models/
│   │   ├── StandardTorrentTests.swift
│   │   ├── TorrentStateTests.swift
│   │   └── ServerTests.swift
│   ├── Utilities/
│   │   ├── TorrentMapperTests.swift
│   │   ├── FormattersTests.swift
│   │   └── TestDataFactory.swift
│   ├── BusinessLogic/
│   │   ├── TorrentManagerTests.swift
│   │   ├── SessionTests.swift
│   │   └── AppPreferencesTests.swift
│   ├── Mocks/
│   │   ├── MockTorrentClientActing.swift
│   │   ├── MockKeychain.swift
│   │   └── MockSession.swift
│   └── Performance/
│       └── TorrentMapperPerformanceTests.swift
```

### Test Execution Strategy
- **Unit Tests**: Fast, isolated tests for individual components
- **Integration Tests**: Test component interactions with mocked dependencies
- **Performance Tests**: Validate performance of critical operations
- **Continuous Integration**: All tests run on every commit

### Coverage Goals
- **Models**: 95%+ coverage (critical for data integrity)
- **Utilities**: 90%+ coverage (high-use components)
- **Business Logic**: 85%+ coverage (complex logic paths)
- **Overall Target**: 80%+ code coverage

## Test Patterns and Best Practices

### Arrange-Act-Assert Pattern
```swift
@Test("Torrent ratio calculation")
func torrentRatioCalculation() {
    // Arrange
    let torrent = TestDataFactory.createStandardTorrent(
        uploaded: 1000,
        downloaded: 500
    )
    
    // Act
    let ratio = torrent.ratio
    
    // Assert
    #expect(ratio == 2.0)
}
```

### Parameterized Tests
```swift
@Test("Torrent state colors", arguments: [
    (TorrentState.downloading, Color.blue),
    (TorrentState.seeding, Color.green),
    (TorrentState.error, Color.red),
    (TorrentState.paused, Color.purple)
])
func torrentStateColors(state: TorrentState, expectedColor: Color) {
    #expect(state.progressColor == expectedColor)
}
```

### Async Testing
```swift
@Test("TorrentManager refresh")
func torrentManagerRefresh() async throws {
    // Setup mock
    let mockClient = MockTorrentClientActing()
    let expectedTorrents = TestDataFactory.createMultipleTorrents(count: 3)
    mockClient.refreshResult = (expectedTorrents, [])
    
    // Test
    let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
    try await manager.refresh()
    
    // Verify
    #expect(mockClient.refreshCallCount == 1)
    #expect(manager.torrents.count == 3)
}
```

## Performance Considerations

### Performance Test Targets
- **TorrentMapper**: Handle 1000+ torrents with <100ms response time
- **StandardTorrent Updates**: Batch updates of 100+ torrents efficiently
- **Memory Usage**: Reasonable memory footprint for large torrent lists

### Performance Test Implementation
```swift
@Test("TorrentMapper performance with large torrent list")
func torrentMapperPerformanceWithLargeTorrentList() {
    let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
    let filterOptions = FilterOptions(states: [.downloading, .seeding])
    let sortOption = SortOption(property: .name)
    
    let clock = ContinuousClock()
    let elapsed = clock.measure {
        _ = TorrentMapper.map(torrents, query: "", 
                            sortOption: sortOption, 
                            filterOptions: filterOptions)
    }
    
    #expect(elapsed < .milliseconds(100), "TorrentMapper should process 1000 torrents in under 100ms")
}
```

## Integration Points

### External Dependencies
- **Keychain**: Mock for secure storage testing
- **Network**: Mock for API interaction testing  
- **UserDefaults**: In-memory for preferences testing
- **Timer**: Controllable for time-dependent testing

### Dependency Injection
```swift
// Enable testability through dependency injection
class TorrentManager {
    init(session: Session, 
         preferences: AppPreferences,
         timer: TimerProtocol = SystemTimer()) {
        // Implementation
    }
}
```

This design provides a comprehensive foundation for implementing robust unit tests that will improve code quality, catch regressions early, and provide confidence when making changes to the Magnesium codebase.