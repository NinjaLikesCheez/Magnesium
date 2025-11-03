//
//  SettingsDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import Router
import SwiftUI
import TorrentUI

/// Navigation destinations for the Settings feature.
enum SettingsDestination: RoutableDestination {
	var id: Self { fatalError("Not yet implemented") }
}

struct SettingsDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: SettingsDestination.self) { destination in
				switch destination {
				default: fatalError("Not yet implemented")
				}
			}
	}
}

extension View {
	func withSettingsDestinations() -> some View {
		modifier(SettingsDestinationModifier())
	}
}
