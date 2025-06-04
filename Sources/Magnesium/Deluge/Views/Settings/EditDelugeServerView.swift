//
//  EditDelugeServerView.swift
//  Magnesium
//
//  Created by ninji on 16/04/2025.
//

import SwiftUI

struct EditDelugeServerView: View {
	@Environment(Router.self) private var router
	@Environment(Session.self) private var session
	@Environment(AppPreferences.self) private var preferences

	@State private var settings: DelugeSettings

	private let server: Server

	init(_ server: Server) {
		self.server = server
		let serverSettings = try! JSONDecoder().decode(DelugeServerSettings.self, from: server.data)
		let keychain = try! JSONDecoder().decode(DelugeKeychainData.self, from: server.keychainData!)

		settings = .init(
			name: server.name,
			address: serverSettings.url.absoluteString,
			password: keychain.password,
			basicAuthentication: keychain.basicAuthentication?.toServerBasicAuthentication() ?? .init()
		)
	}

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
			additionalSections: {
				Button("Delete", role: .destructive) {
					do {
						try preferences.remove(server: server)
						router.pop()
					} catch {
						// TODO: Error handle
						print("Failed to remove server: \(server)")
					}
				}
				.frame(maxWidth: .infinity, alignment: .center)
			}
		)
		.navigationTitle("Deluge Settings")
	}

	private func save() async throws {
		// TODO: Error handle
		let server = try await settings.makeServer()
		try preferences.addOrUpdate(server: server)
		session.setServer(server)
		router.pop()
	}
}
