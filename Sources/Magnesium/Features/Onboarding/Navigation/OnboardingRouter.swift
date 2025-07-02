//
//  OnboardingRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation

/// Router for the Onboarding feature flow.
/// 
/// Handles navigation during the initial app setup process, providing:
/// - Push navigation to server setup screens
/// - Modal presentation for server addition workflows
/// 
/// **Destinations:**
/// - `.addNewServer(ServerType)`: Navigate to add a specific server type (push navigation)
/// 
/// **Sheets:**
/// - `.addNewServer(ServerType)`: Present server addition as a modal (modal presentation)
/// 
/// **Usage:**
/// ```swift
/// @Environment(OnboardingRouter.self) private var router
/// 
/// // Navigate to add server (push)
/// router.push(.addNewServer(.deluge))
/// 
/// // Present add server as sheet (modal)
/// router.presentSheet(.addNewServer(.qbittorrent))
/// ```
/// 
/// **Note:** This router supports both push and modal presentation for server addition,
/// allowing flexibility in the onboarding user experience.
@Observable
final class OnboardingRouter: RouterProtocol {
	typealias Destination = OnboardingDestinations
	typealias Sheet = OnboardingSheets

	var path: [OnboardingDestinations] = []
	var presentedSheet: OnboardingSheets? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
