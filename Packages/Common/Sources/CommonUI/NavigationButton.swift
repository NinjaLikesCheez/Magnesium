//
//  NavigationButton.swift
//  Common
//
//  Created by ninji on 16/07/2026.
//
import SwiftUI

public struct NavigationButton: View {
	public typealias Action = () -> Void

	private let title: String
	private let action: Action

	public init(_ title: String, action: @escaping Action) {
		self.title = title
		self.action = action
	}

	public var body: some View {
		Button {
			action()
		} label: {
			NavigationLink(title, destination: EmptyView())
		}
		.foregroundStyle(.primary)
	}
}
