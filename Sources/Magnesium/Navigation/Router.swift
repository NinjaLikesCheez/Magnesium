//
//  Router.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import Observation
import SwiftUI

protocol RoutableDestination: Hashable {}
protocol RoutableSheet: Hashable, Identifiable {}

@MainActor
@Observable
final class Router<Destination: RoutableDestination, Sheet: RoutableSheet> {
	var path = [Destination]()
	var presentedSheet: Sheet?

	init() {}

	func push(_ destination: Destination) {
		path.append(destination)
	}

	@discardableResult
	func pop() -> Destination? {
		path.popLast()
	}

	func popToRoot() {
		path.removeAll()
	}

	func presentSheet(_ sheet: Sheet) {
		presentedSheet = sheet
	}

	func dismissSheet() {
		presentedSheet = nil
	}
}
