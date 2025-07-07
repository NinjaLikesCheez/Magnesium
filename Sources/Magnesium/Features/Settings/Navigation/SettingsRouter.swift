//
//  SettingsRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation

/// Handles navigation within the settings screen.
@Observable
final class SettingsRouter: RouterProtocol {
	typealias Destination = SettingsDestination
	typealias Sheet = SettingsSheet

	var path: [SettingsDestination] = []
	var presentedSheet: SettingsSheet? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
