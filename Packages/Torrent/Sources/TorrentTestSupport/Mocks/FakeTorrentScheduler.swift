import Foundation
import TorrentManager

/// A `TorrentScheduling` fake that never touches a real run loop.
/// Tests call `fire()` to simulate an interval elapsing.
@MainActor
public final class FakeTorrentScheduler: TorrentScheduling {
	public final class ScheduleHandle: Cancellable {
		public private(set) var isCancelled = false

		public func invalidate() {
			isCancelled = true
		}
	}

	private struct Schedule {
		let interval: TimeInterval
		let action: @Sendable () -> Void
		let handle: ScheduleHandle
	}

	public private(set) var scheduledIntervals: [TimeInterval] = []
	private var scheduled: [Schedule] = []

	public init() {}

	public func schedule(interval: TimeInterval, action: @escaping @Sendable () -> Void) -> Cancellable {
		let handle = ScheduleHandle()
		scheduledIntervals.append(interval)
		scheduled.append(Schedule(interval: interval, action: action, handle: handle))
		return handle
	}

	/// Number of schedules that are still active (i.e. haven't been invalidated).
	public var activeScheduleCount: Int {
		scheduled.filter { !$0.handle.isCancelled }.count
	}

	/// Simulates the most recently scheduled, still-active interval elapsing once.
	public func fire() {
		guard let latest = scheduled.last(where: { !$0.handle.isCancelled }) else { return }
		latest.action()
	}

	/// Simulates the most recently scheduled, still-active interval elapsing `times` times.
	public func fire(times: Int) {
		for _ in 0..<times {
			fire()
		}
	}
}
