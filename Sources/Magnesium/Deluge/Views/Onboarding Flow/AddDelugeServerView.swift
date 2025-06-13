//
//  AddDelugeServerView.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import SwiftUI

struct AddDelugeServerView<Router: RouterProtocol>: View {
	@Environment(Router.self) var router
	@Environment(AppPreferences.self) private var preferences
	@Environment(\.isPresented) private var isPresented

	@State private var settings: DelugeSettings = .init()

	var body: some View {
		ServerSettingsView(
			name: $settings.name,
			address: $settings.address,
			basicAuthentication: $settings.basicAuthentication,
			onSave: {
				Task {
					do {
						try await save()
					} catch {
						print("Error saving settings: \(error)")
					}
				}
			},
			saveButtonEnabled: {
				settings.isValid
			},
			additionalSettings: {
				SecureField("Password", text: $settings.password.projectedValue)
					.textContentType(.password)
					.autocorrectionDisabled()
					.autocapitalization(.none)
			},
			additionalSections: {}
		)
		.navigationTitle("Deluge Settings")
	}

	private func save() async throws {
		// TODO: Error handle
		let server = try await settings.makeServer()
		try preferences.addOrUpdate(server: server)

		if isPresented {
			router.dismissSheet(withParent: true)
		} else {
			router.pop()
		}
	}
}
