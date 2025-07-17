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
        
        // Create a real timer but don't schedule it - we'll control it manually
        let timer = Timer(timeInterval: interval, repeats: repeats) { timer in
            block(timer)
        }
        return timer
    }
    
    func invalidate() {
        invalidateCallCount += 1
        isValid = false
        timerBlock = nil
    }
    
    // MARK: - Test Helpers
    
    private var mockTimerInstance: Timer?
    
    func fire() {
        guard isValid, let block = timerBlock else { return }
        
        // Create a timer instance for the callback if we don't have one
        if mockTimerInstance == nil {
            mockTimerInstance = Timer(timeInterval: interval, repeats: isRepeating) { _ in }
        }
        
        if let timer = mockTimerInstance {
            block(timer)
        }
        
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

