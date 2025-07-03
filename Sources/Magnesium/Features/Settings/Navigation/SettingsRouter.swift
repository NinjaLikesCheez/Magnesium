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
	typealias Destination = SettingsDestinations
	typealias Sheet = SettingsSheets

	var path: [SettingsDestinations] = []
	var presentedSheet: SettingsSheets? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
