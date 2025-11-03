import Router
//
//  OnboardingSheets.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import SwiftUI

/// Modal presentations for the Onboarding feature.
enum OnboardingSheet: RoutableSheet {
	var id: Self { self }

	/// Add a new server of a specific type
	case addNewServer(TorrentServerType)
}

struct OnboardingSheetModifier: RoutableSheetViewModifier {
	@Binding var router: OnboardingRouter
	@Binding var preferences: TorrentPreferences
	@Binding var session: TorrentSession

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in
				switch sheet {
				case .addNewServer(let server):
					NavigationStack {
						switch server {
						case .deluge:
							AddDelugeServerView<OnboardingRouter>()
						case .qbittorrent:
							AddQBittorrentServerView<OnboardingRouter>()
						}
					}
				}
			}
	}
}

extension View {
	func withOnboardingSheets(
		router: Binding<OnboardingRouter>,
		preferences: Binding<TorrentPreferences>,
		session: Binding<TorrentSession>
	) -> some View {
		modifier(OnboardingSheetModifier(router: router, preferences: preferences, session: session))
	}
}
