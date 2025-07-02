//
//  Router.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import Observation
import SwiftUI

protocol RoutableDestinations: Hashable {}
protocol RoutableSheets: Hashable, Identifiable {}

protocol RoutableSheetsViewModifible: ViewModifier {}
protocol RoutableDestinationsViewModifible: ViewModifier {}

@MainActor
protocol RouterProtocol: AnyObject, Observation.Observable {
	associatedtype Destination: RoutableDestinations
	associatedtype Sheet: RoutableSheets

	var path: [Destination] { get set }
	var presentedSheet: Sheet? { get set }
	var parent: (any RouterProtocol)? { get }

	init(_ parent: (any RouterProtocol)?)

	func push(_ destination: Destination)
	@discardableResult func pop() -> Destination?
	func popToRoot()
	func presentSheet(_ sheet: Sheet)
	func dismissSheet(withParent: Bool)
	func reset(withParent: Bool)
}

extension RouterProtocol {
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

	func dismissSheet(withParent: Bool = false) {
		presentedSheet = nil
		if withParent {
			parent?.dismissSheet()
		}
	}

	func reset(withParent: Bool = false) {
		presentedSheet = nil
		popToRoot()
		if withParent {
			parent?.reset()
		}
	}
}
