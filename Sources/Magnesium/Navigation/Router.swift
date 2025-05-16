//
//  Router.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import Observation
import SwiftUI

class AnySheetDestination: Identifiable {
	let destination: any Identifiable

	init(_ destination: any Identifiable) {
		self.destination = destination
	}
}

@Observable
final class Router {
	let name: String
	var path = NavigationPath()
	var presentedSheet: AnySheetDestination? = nil

	init(_ name: String) {
		self.name = name
	}

	func present(_ destination: any Identifiable) {
		presentedSheet = AnySheetDestination(destination)
	}

	func push(_ destination: any Hashable) {
		path.append(destination)
	}

	func pop() {
		path.removeLast()
	}

	func popToRoot() {
		path.removeLast(path.count)
	}
}

struct RoutableNavigationLink<Content: View>: View {
	let content: () -> Content
	let action: () -> Void
	let disclosure: Bool

	init(@ViewBuilder content: @escaping () -> Content, action: @escaping () -> Void, disclosure: Bool = true) {
		self.content = content
		self.action = action
		self.disclosure = disclosure
	}

	var body: some View {
		HStack {
			content()
			if disclosure {
				Spacer()
				Image(systemName: "chevron.forward")
					.font(Font.system(.caption).weight(.bold))
					.foregroundColor(Color(UIColor.tertiaryLabel))
			}
		}
		.contentShape(Rectangle())
		.onTapGesture {
			action()
		}
	}
}
