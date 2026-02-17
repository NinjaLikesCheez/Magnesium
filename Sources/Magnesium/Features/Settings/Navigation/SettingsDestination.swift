//
//  SettingsDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import Router
import SwiftUI
import TorrentUI
import MagnesiumModule

/// Navigation destinations for the Settings feature.
enum SettingsDestination: RoutableDestination {
	var id: Self { self }

	case moduleSettings(AppModules.ModuleType)
}

struct SettingsDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: SettingsDestination.self) { destination in
				switch destination {
				case let .moduleSettings(moduleType):
					switch moduleType {
					case let .torrent(module):
						module.settings
					}
				}
			}
	}
}

extension View {
	func withSettingsDestinations() -> some View {
		modifier(SettingsDestinationModifier())
	}
}
