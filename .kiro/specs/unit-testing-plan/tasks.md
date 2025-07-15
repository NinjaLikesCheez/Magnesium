# Implementation Plan

- [x] 1. Set up Swift Testing framework and test infrastructure
  - Configure Swift Testing framework in the existing MagnesiumTests target
  - Update Package.swift or project configuration to include Swift Testing
  - Create base test utilities and helper functions
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 2. Create test data factories and mock implementations
- [x] 2.1 Implement TestDataFactory for creating test objects
  - Write factory methods for StandardTorrent with configurable properties
  - Write factory methods for Server, TorrentState, and other core models
  - Create methods for generating multiple test objects with variations
  - _Requirements: 6.4_

- [x] 2.2 Create MockTorrentClientActing implementation
  - Implement mock TorrentClientActing protocol with configurable responses
  - Add tracking for method calls and parameters
  - Include error simulation capabilities for testing error handling
  - _Requirements: 6.1_

- [x] 2.3 Create MockKeychain implementation
  - Implement in-memory keychain for testing secure storage operations
  - Add change publisher functionality for testing reactive behavior
  - Include error simulation for keychain operation failures
  - _Requirements: 6.2_

- [x] 2.4 Create additional mock implementations
  - Implement MockSession for testing session management
  - Create MockAppPreferences for testing preference operations
  - Add MockTimer for testing time-dependent functionality
  - _Requirements: 6.3_

- [x] 3. Implement core model tests
- [x] 3.1 Create StandardTorrent tests
  - Write tests for StandardTorrent initialization with all properties
  - Test the update method for correctly updating mutable properties
  - Test computed properties: ratio, isActive, localizedSpeed, localizedProgress
  - Test equality and hashing behavior consistency
  - Test edge cases: infinite ratios, zero values, negative values
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 3.2 Create TorrentState tests
  - Test all enum cases and their string representations
  - Test localizedString property returns correct localized values
  - Test progressColor property returns correct colors for each state
  - Test Codable conformance for encoding and decoding
  - _Requirements: 1.4_

- [x] 3.3 Create Server model tests
  - Test Server initialization with all required properties
  - Test Codable conformance for proper encoding/decoding
  - Test Identifiable conformance and id property behavior
  - Test equality and hashing for Server instances
  - _Requirements: 1.5_

- [x] 4. Implement utility class tests
- [x] 4.1 Create TorrentMapper filtering tests
  - Test filtering torrents by single and multiple states
  - Test filtering torrents by single and multiple labels
  - Test search functionality with various query strings
  - Test combined filtering operations (state + label + search)
  - Test edge cases: empty filters, empty torrent lists, special characters
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 4.2 Create TorrentMapper sorting tests
  - Test sorting by name with case-insensitive and numeric ordering
  - Test sorting by dateAdded in ascending and descending order
  - Test sorting by downloadSpeed and uploadSpeed
  - Test sorting by progress percentage
  - Test sort stability and secondary sorting behavior
  - _Requirements: 2.4_

- [x] 4.3 Create Formatters tests
  - Test byte count formatting with various sizes and units
  - Test percentage formatting with different precision levels
  - Test ETA formatting for various time intervals
  - Test number formatting with different precision requirements
  - Test locale-specific formatting behavior
  - _Requirements: 2.5_

- [ ] 5. Implement business logic tests
- [ ] 5.1 Create AppPreferences tests
  - Test server addition and update operations
  - Test server removal and cleanup of keychain data
  - Test selected server management and persistence
  - Test sort and filter option storage and retrieval
  - Test preferences reset functionality
  - Test error handling for keychain operations
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 5.2 Create Session tests
  - Test action implementation creation for different server types
  - Test server switching and action implementation updates
  - Test error handling for missing keychain data
  - Test error handling for decoding failures
  - Test session reset functionality
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 5.3 Create TorrentManager tests
  - Test torrent refresh with delta updates for existing torrents
  - Test adding new torrents and removing deleted torrents
  - Test filtered torrents computation with search, sort, and filter
  - Test total upload and download speed calculations
  - Test torrent action delegation (resume, pause, delete, addLink)
  - Test timer-based auto-refresh functionality
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 6. Implement error handling and edge case tests
- [ ] 6.1 Create comprehensive error handling tests
  - Test Session.Error cases with appropriate error messages
  - Test keychain operation error handling and recovery
  - Test network operation failure scenarios
  - Test invalid data handling and graceful degradation
  - _Requirements: 7.2, 7.3_

- [ ] 6.2 Create edge case and boundary tests
  - Test behavior with empty torrent lists and zero values
  - Test handling of extremely large numbers and overflow scenarios
  - Test Unicode and special character handling in torrent names
  - Test concurrent access and thread safety where applicable
  - _Requirements: 7.2, 7.4_

- [ ] 7. Implement performance tests
- [ ] 7.1 Create TorrentMapper performance tests
  - Test filtering performance with 1000+ torrents under 100ms
  - Test sorting performance with large datasets
  - Test combined operations performance (filter + sort + search)
  - Test memory usage during large torrent list processing
  - _Requirements: 7.1_

- [ ] 7.2 Create TorrentManager performance tests
  - Test torrent refresh performance with large delta updates
  - Test memory efficiency during torrent list management
  - Test timer performance and resource cleanup
  - _Requirements: 7.1, 7.4_

- [ ] 8. Create integration tests with mocked dependencies
- [ ] 8.1 Test TorrentManager with mocked Session and AppPreferences
  - Test complete torrent management workflow with mocked dependencies
  - Test error propagation through the component stack
  - Test state consistency across component interactions
  - _Requirements: 4.4, 5.5_

- [ ] 8.2 Test Session with mocked keychain operations
  - Test complete server setup workflow with mocked keychain
  - Test server switching with persistent state management
  - Test error recovery and fallback behavior
  - _Requirements: 4.4_

- [ ] 9. Finalize test suite and documentation
- [ ] 9.1 Add test suite organization and documentation
  - Organize tests into logical suites with descriptive names
  - Add inline documentation for complex test scenarios
  - Create README for test suite explaining structure and conventions
  - _Requirements: 6.4_

- [ ] 9.2 Validate test coverage and quality
  - Run test coverage analysis to ensure 80%+ overall coverage
  - Verify critical paths have 90%+ coverage (models, utilities)
  - Review test quality and maintainability
  - Add any missing test cases identified during coverage analysis
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5_