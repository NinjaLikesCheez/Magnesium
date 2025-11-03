//
//  AppState.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

enum AppState: Sendable {
	case unboarded
	case onboarded
	case resuming
	case error(Error)
}
