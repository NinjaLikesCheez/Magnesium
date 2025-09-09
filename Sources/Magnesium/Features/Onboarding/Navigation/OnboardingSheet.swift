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
	case addNewServer(ServerType)
}

struct OnboardingSheetModifier: RoutableSheetViewModifier {
	@Binding var router: OnboardingRouter
	@Binding var preferences: AppPreferences
	@Binding var session: Session

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
		preferences: Binding<AppPreferences>,
		session: Binding<Session>
	) -> some View {
		modifier(OnboardingSheetModifier(router: router, preferences: preferences, session: session))
	}
}
