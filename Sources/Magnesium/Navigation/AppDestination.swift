//
//  AppDestinations.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//
import SwiftUI
import Router

/// Navigation destinations for the App.
enum AppDestination: RoutableDestination {
	var id: Self { fatalError("Not yet implemented") }
}

struct AppDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: AppDestination.self) { destination in
				switch destination {
				default: fatalError("Not yet implemented")
				}
			}
	}
}

extension View {
	func withAppDestinations() -> some View {
		modifier(AppDestinationModifier())
	}
}
