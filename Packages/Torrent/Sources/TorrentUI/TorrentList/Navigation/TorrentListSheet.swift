//
//  TorrentListSheets.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI
import Router

/// Modal presentations for the TorrentList feature.
enum TorrentListSheet: RoutableSheet {
	var id: Self { fatalError("Not implemented") }
}

struct TorrentListSheetViewModifier: ViewModifier {
	@Binding var router: TorrentListRouter
	@Binding var preferences: TorrentPreferences
	@Binding var session: TorrentSession

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in }
	}
}

extension View {
	func withTorrentListSheets(
		router: Binding<TorrentListRouter>,
		preferences: Binding<TorrentPreferences>,
		session: Binding<TorrentSession>
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
