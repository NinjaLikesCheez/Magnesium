//
//  SettingsRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation

/// Router for the Settings feature flow.
/// 
/// Handles navigation within the settings screen, including:
/// - Server management (add, edit servers)
/// - Navigation to server-specific configuration screens
/// 
/// **Destinations:**
/// - `.editServer(Server)`: Navigate to edit an existing server
/// - `.addAServer`: Navigate to the server selection screen
/// - `.addNewServer(ServerType)`: Navigate to add a specific server type
/// 
/// **Usage:**
/// ```swift
/// @Environment(SettingsRouter.self) private var router
/// 
/// // Navigate to edit a server
/// router.push(.editServer(selectedServer))
/// 
/// // Navigate to add server selection
/// router.push(.addAServer)
/// ```
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
