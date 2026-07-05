//
//  AppSheets.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//
import Router
import SwiftUI

/// Modal presentations for the App.
enum AppSheet: RoutableSheet {
	var id: Self { self }

	case settings
}

struct AppSheetModifier: RoutableSheetViewModifier {
	@Bindable var router: AppRouter
	let modules: AppModules

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in
				switch sheet {
				case .settings:
					SettingsFlow(router: SettingsRouter(router))
						.environment(modules)
				}
			}
	}
}

extension View {
	func withAppSheets(router: AppRouter, modules: AppModules) -> some View {
		modifier(AppSheetModifier(router: router, modules: modules))
	}
}
