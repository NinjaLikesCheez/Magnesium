import Router
//
//  TorrentOnboardingSheets.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import SwiftUI

/// Modal presentations for the Onboarding feature.
public enum TorrentOnboardingSheet: RoutableSheet {
	public var id: Self { self }

	/// Add a new server of a specific type
	case addNewServer(TorrentServerType)
}

struct TorrentOnboardingSheetModifier: RoutableSheetViewModifier {
	@Bindable var router: TorrentOnboardingRouter
	let preferences: TorrentPreferences
	let session: TorrentSession

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in
				switch sheet {
				case .addNewServer(let server):
					NavigationStack {
						switch server {
						case .deluge:
							AddDelugeServerView<TorrentOnboardingRouter>()
						case .qbittorrent:
							AddQBittorrentServerView<TorrentOnboardingRouter>()
						}
					}
				}
			}
	}
}

extension View {
	func withTorrentOnboardingSheets(
		router: TorrentOnboardingRouter,
		preferences: TorrentPreferences,
		session: TorrentSession
	) -> some View {
		modifier(TorrentOnboardingSheetModifier(router: router, preferences: preferences, session: session))
	}
}
