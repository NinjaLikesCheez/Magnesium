//
//  TorrentOnboardingRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//

import Observation
import Router

/// Router for the Onboarding feature flow.
///
/// Handles navigation during the initial app setup process for server
/// configuration.
@Observable
public final class TorrentOnboardingRouter: Routable {
	public typealias Destination = TorrentOnboardingDestination
	public typealias Sheet = TorrentOnboardingSheet
	public typealias Error = TorrentOnboardingError

	public var path: [Destination] = []
	public var presentedSheet: Sheet? = nil
	public var presentedError: Error? = nil
	public let parent: (any Routable)?

	public required init(_ parent: (any Routable)? = nil) {
		self.parent = parent
	}
}
