//
//  Router.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import Observation
import SwiftUI

public protocol RoutableDestination: Hashable {}
public protocol RoutableSheet: Hashable, Identifiable {}
public protocol RoutableError: Hashable, Identifiable {}

public protocol RoutableSheetViewModifier: ViewModifier {}
public protocol RoutableDestinationViewModifier: ViewModifier {}
public protocol RoutableErrorViewModifier: ViewModifier {}

@MainActor
public protocol RouterProtocol: AnyObject, Observation.Observable {
	associatedtype Destination: RoutableDestination
	associatedtype Sheet: RoutableSheet
	associatedtype Error: RoutableError

	var path: [Destination] { get set }
	var presentedSheet: Sheet? { get set }
	var presentedError: Error? { get set }
	var parent: (any RouterProtocol)? { get }

	init(_ parent: (any RouterProtocol)?)

	func push(_ destination: Destination)
	@discardableResult func pop() -> Destination?
	func popToRoot()
	func presentSheet(_ sheet: Sheet)
	func presentError(_ error: Error)
	func dismissSheet(withParent: Bool)
	func dismissError()
	func reset(withParent: Bool)
}

public extension RouterProtocol {
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

	func presentError(_ error: Error) {
		presentedError = error
	}

	func dismissSheet(withParent: Bool = false) {
		presentedSheet = nil
		if withParent {
			parent?.dismissSheet()
		}
	}

	func dismissError() {
		presentedError = nil
	}

	func reset(withParent: Bool = false) {
		presentedSheet = nil
		popToRoot()
		if withParent {
			parent?.reset()
		}
	}
}
