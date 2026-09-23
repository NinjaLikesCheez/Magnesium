//
//  TorrentScheduling.swift
//  Magnesium
//

import Foundation

/// A handle to a scheduled repeating action. Invalidate to stop future firings.
@MainActor
public protocol Cancellable {
	func invalidate()
}

extension Timer: Cancellable {}

/// Abstracts repeating, interval-based scheduling so callers (like `TorrentManager`) don't depend on `Timer` directly.
///
/// A real `Timer` fires on the run loop on a wall-clock cadence, which makes anything that depends on it
/// slow or flaky to test. Substitute `TorrentScheduling` with a fake in tests to drive `action` deterministically.
@MainActor
public protocol TorrentScheduling {
	/// Schedules `action` to run repeatedly every `interval` seconds.
	/// Returns a handle that stops the schedule when invalidated.
	func schedule(interval: TimeInterval, action: @escaping @Sendable () -> Void) -> Cancellable
}

/// `TorrentScheduling` backed by a real `Timer.scheduledTimer`.
public struct LiveTorrentScheduler: TorrentScheduling {
	public init() {}

	public func schedule(interval: TimeInterval, action: @escaping @Sendable () -> Void) -> Cancellable {
		Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
			action()
		}
	}
}
