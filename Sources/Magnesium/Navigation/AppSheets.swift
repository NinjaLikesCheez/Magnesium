//
//  SheetDestinations.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//
import SwiftUI

enum AppSheet: RoutableSheets {
	var id: Self { self }

	case addServer(ServerType)
	case settings
}

struct AppSheets: ViewModifier {
	@Binding var router: AppRouter
	@Binding var preferences: AppPreferences
	@Binding var session: Session

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in
				switch sheet {
				case .settings:
					SettingsFlow(settingsRouter: .init(router))
				case .addServer(let server):
					NavigationStack {
						switch server {
						case .deluge:
							AddDelugeServerView<AppRouter>()
						case .qbittorrent:
							AddQBittorrentServerView<AppRouter>()
						}
					}
				}
			}
	}
}

extension View {
	func withAppSheets(
		router: Binding<AppRouter>,
		preferences: Binding<AppPreferences>,
		session: Binding<Session>
	) -> some View {
		modifier(AppSheets(router: router, preferences: preferences, session: session))
	}
}
