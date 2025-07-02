//
//  SettingsRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation

/// Router for the Settings feature flow.
/// 
/// Handles navigation within the settings screen for server management
/// and configuration-related workflows.
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
