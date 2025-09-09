//
//  SettingsRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation
import Router

/// Handles navigation within the settings screen.
@Observable
final class SettingsRouter: RouterProtocol {
	typealias Destination = SettingsDestination
	typealias Sheet = SettingsSheet
	typealias Error = SettingsError

	var path: [Destination] = []
	var presentedSheet: Sheet? = nil
	var presentedError: Error? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
