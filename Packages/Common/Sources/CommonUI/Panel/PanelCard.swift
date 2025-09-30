//
//  PanelCard.swift
//  Magnesium
//
//  Created by ninji on 09/07/2025.
//

/* Based on https://github.com/reddavis/Panel/ */

// MIT License
//
// Copyright (c) 2022 Red Davis
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Common
import SwiftUI

public struct ErrorPanelCard: View {
	let error: any VisualError

	let primaryButtonTitle: String
	let secondaryButtonTitle: String?

	let primaryButtonAction: () -> Void
	let secondaryButtonAction: (() -> Void)?

	public init(
		error: any VisualError,
		primaryButtonTitle: String = "Done",
		primaryButtonAction: @escaping () -> Void,
		secondaryButtonTitle: String? = nil,
		secondaryButtonAction: (() -> Void)? = nil,
	) {
		self.error = error
		self.primaryButtonTitle = primaryButtonTitle
		self.primaryButtonAction = primaryButtonAction

		self.secondaryButtonTitle = secondaryButtonTitle
		self.secondaryButtonAction = secondaryButtonAction
	}

	public var body: some View {
		PanelCard(
			title: error.title,
			systemName: error.systemName,
			subtitle: error.subtitle,
			primaryButtonTitle: primaryButtonTitle,
			primaryButtonAction: primaryButtonAction,
		)
	}
}

public struct PanelCard: View {
	let title: String
	let systemName: String
	let subtitle: String?

	let primaryButtonTitle: String
	let secondaryButtonTitle: String?

	let primaryButtonAction: () -> Void
	let secondaryButtonAction: (() -> Void)?

	public init(
		title: String,
		systemName: String,
		subtitle: String? = nil,
		primaryButtonTitle: String = "Done",
		primaryButtonAction: @escaping () -> Void,
		secondaryButtonTitle: String? = nil,
		secondaryButtonAction: (() -> Void)? = nil,
	) {
		self.title = title
		self.systemName = systemName
		self.subtitle = subtitle
		self.primaryButtonTitle = primaryButtonTitle
		self.primaryButtonAction = primaryButtonAction

		self.secondaryButtonTitle = secondaryButtonTitle
		self.secondaryButtonAction = secondaryButtonAction
	}

	public var body: some View {
		VStack(spacing: 24) {
			VStack(spacing: 32) {
				Text(title)
					.font(.title)
					.multilineTextAlignment(.center)

				Image(systemName: systemName)
					.font(.system(size: 100))

				if let subtitle {
					Text(subtitle)
						.multilineTextAlignment(.center)
				}
			}

			HStack {
				if let secondaryButtonTitle, let secondaryButtonAction {
					Button {
						secondaryButtonAction()
					} label: {
						Text(secondaryButtonTitle)
							.frame(maxWidth: .infinity)
					}
					.buttonStyle(.borderedProminent)
					.tint(.secondary)
					.controlSize(.large)
				}

				Button {
					primaryButtonAction()
				} label: {
					Text(primaryButtonTitle)
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.large)
			}
		}
	}
}
