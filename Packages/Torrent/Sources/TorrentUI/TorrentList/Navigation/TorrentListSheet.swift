//
//  TorrentListSheets.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI
import Router

/// Modal presentations for the TorrentList feature.
public enum TorrentListSheet: RoutableSheet {
	public var id: Self { fatalError("Not implemented") }
}

struct TorrentListSheetViewModifier: ViewModifier {
	@Bindable var router: TorrentListRouter
	let preferences: TorrentPreferences
	let session: TorrentSession

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in }
	}
}

extension View {
	func withTorrentListSheets(
		router: TorrentListRouter,
		preferences: TorrentPreferences,
		session: TorrentSession
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
