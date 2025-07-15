import Foundation
@testable import Magnesium

/// Protocol for timer functionality to enable mocking
protocol TimerProtocol {
    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer
    func invalidate()
}

/// System timer implementation
class SystemTimer: TimerProtocol {
    private var timer: Timer?
    
    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
        self.timer = timer
        return timer
    }
    
    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
}

/// Mock timer implementation for testing
class MockTimer: TimerProtocol {
    // MARK: - Mock Configuration
    
    var scheduledTimerCallCount = 0
    var scheduledTimerCalls: [(TimeInterval, Bool)] = []
    var invalidateCallCount = 0
    
    private var timerBlock: ((Timer) -> Void)?
    private var isRepeating = false
    private var interval: TimeInterval = 0
    private var isValid = false
    
    // MARK: - TimerProtocol Implementation
    
    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        scheduledTimerCallCount += 1
        scheduledTimerCalls.append((interval, repeats))
        
        self.timerBlock = block
        self.isRepeating = repeats
        self.interval = interval
        self.isValid = true
        
        // Return a mock timer object
        return MockTimerInstance(mockTimer: self)
    }
    
    func invalidate() {
        invalidateCallCount += 1
        isValid = false
        timerBlock = nil
    }
    
    // MARK: - Test Helpers
    
    func fire() {
        guard isValid, let block = timerBlock else { return }
        block(MockTimerInstance(mockTimer: self))
        
        if !isRepeating {
            invalidate()
        }
    }
    
    func fireMultipleTimes(_ count: Int) {
        for _ in 0..<count {
            fire()
            if !isValid { break }
        }
    }
    
    var isTimerValid: Bool {
        return isValid
    }
    
    var currentInterval: TimeInterval {
        return interval
    }
    
    var isTimerRepeating: Bool {
        return isRepeating
    }
    
    func reset() {
        scheduledTimerCallCount = 0
        scheduledTimerCalls.removeAll()
        invalidateCallCount = 0
        timerBlock = nil
        isRepeating = false
        interval = 0
        isValid = false
    }
}

/// Mock Timer instance that conforms to Timer-like interface
private class MockTimerInstance: Timer {
    private weak var mockTimer: MockTimer?
    
    init(mockTimer: MockTimer) {
        self.mockTimer = mockTimer
        super.init()
    }
    
    override func invalidate() {
        mockTimer?.invalidate()
    }
    
    override var isValid: Bool {
        return mockTimer?.isTimerValid ?? false
    }
}