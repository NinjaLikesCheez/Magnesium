//
//  TorrentListSheets.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI
import Router
import Torrent

/// Modal presentations for the TorrentList feature.
enum TorrentListSheet: RoutableSheet {
	var id: Self { self }

	/// Present the settings screen
	case settings
}

struct TorrentListSheetViewModifier: ViewModifier {
	@Binding var router: TorrentListRouter
	@Binding var preferences: TorrentPreferences
	@Binding var session: Session

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in
				switch sheet {
				case .settings:
					SettingsFlow(settingsRouter: .init(router))
				}
			}
	}
}

extension View {
	func withTorrentListSheets(
		router: Binding<TorrentListRouter>,
		preferences: Binding<TorrentPreferences>,
		session: Binding<Session>
	) -> some View {
		modifier(
			TorrentListSheetViewModifier(
				router: router,
				preferences: preferences,
				session: session
			)
		)
	}
}
