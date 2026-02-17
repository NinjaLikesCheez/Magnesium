//
//  SettingsRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation
import Router
import SwiftUI

/// Handles navigation within the settings screen.
@Observable
public final class TorrentSettingsRouter: Routable {
	public typealias Destination = TorrentSettingsDestination
	public typealias Sheet = TorrentSettingsSheet
	public typealias Error = TorrentSettingsError

	public var path = NavigationPath()
	public var presentedSheet: Sheet? = nil
	public var presentedError: Error? = nil
	public let parent: (any Routable)?

	public required init(_ parent: (any Routable)? = nil) {
		self.parent = parent
	}
}
