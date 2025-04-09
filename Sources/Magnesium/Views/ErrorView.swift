//
//  ErrorView.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct ErrorView: View {
	var message: String
	var buttonTitle: String
	var action: () async throws -> Void

	init(message: String, buttonTitle: String = "Retry", action: @escaping () async throws -> Void) {
		self.message = message
		self.buttonTitle = buttonTitle
		self.action = action
	}

	var body: some View {
		VStack(alignment: .center) {
			Text(message)
				 .font(.largeTitle)
				 .padding()

			Button(buttonTitle) {
				Task {
					try await action()
				}
			}
			.buttonStyle(.borderedProminent)
		}
		.opacity(1)
	}
}
