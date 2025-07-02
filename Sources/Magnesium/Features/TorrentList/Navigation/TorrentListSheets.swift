//
//  TorrentListSheets.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI

/// Modal presentations for the TorrentList feature.
/// 
/// Defines all possible sheet presentations within the torrent list flow.
enum TorrentListSheet: RoutableSheets {
	var id: Self { self }

	/// Present the settings modal as a sheet
	case settings
}

struct TorrentListSheetViewModifier: ViewModifier {
	@Binding var router: TorrentListRouter
	@Binding var preferences: AppPreferences
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
		preferences: Binding<AppPreferences>,
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
