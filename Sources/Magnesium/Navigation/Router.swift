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
protocol RoutableError: Hashable {}

protocol RoutableSheetViewModifier: ViewModifier {}
protocol RoutableDestinationViewModifier: ViewModifier {}
protocol RoutableErrorViewModifier: ViewModifier {}

@MainActor
protocol RouterProtocol: AnyObject, Observation.Observable {
	associatedtype Destination: RoutableDestination
	associatedtype Sheet: RoutableSheet
	// associatedtype Error: RoutableError

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
