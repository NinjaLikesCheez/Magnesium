//
//  ObservationTracking.swift
//  Magnesium
//
//  Created by ninji on 16/04/2025.
//

import Observation
import Foundation

// https://www.polpiella.dev/observable-outside-of-a-view

public func withObservationTracking<T: Sendable>(
	of value: @escaping @autoclosure () -> T,
	execute: @escaping (T) -> Void
) {
	Observation.withObservationTracking {
		execute(value())
	} onChange: {
		RunLoop.current.perform {
			withObservationTracking(of: value(), execute: execute)
		}
	}
}
