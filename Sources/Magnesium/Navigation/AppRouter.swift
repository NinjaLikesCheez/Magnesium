//
//  AppRouter.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//
import Observation
import Router
import SwiftUI

/// Handles navigation within the app.
@Observable
final class AppRouter: Routable {
	typealias Destination = AppDestination
	typealias Sheet = AppSheet
	typealias Error = AppError

	var path = NavigationPath()
	var presentedSheet: Sheet? = nil
	var presentedError: Error? = nil
	let parent: (any Routable)?

	required init(_ parent: (any Routable)? = nil) {
		self.parent = parent
	}
}
