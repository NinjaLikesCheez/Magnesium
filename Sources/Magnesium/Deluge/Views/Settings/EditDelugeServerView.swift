//
//  EditDelugeServerView.swift
//  Magnesium
//
//  Created by ninji on 16/04/2025.
//

import Router
import SwiftUI

struct EditDelugeServerView: View {
	@Environment(SettingsRouter.self) private var router
	@Environment(Session.self) private var session
	@Environment(AppPreferences.self) private var preferences
	@Environment(\.isPresented) private var isPresented

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
					await save()
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
					do throws(AppPreferences.Error) {
						try preferences.remove(server: server)
						router.pop()
					} catch {
						router.presentError(.preferences(error))
					}
				}
				.frame(maxWidth: .infinity, alignment: .center)
			}
		)
		.navigationTitle("Deluge Settings")
	}

	private func save() async {
		do {
			let server = try await settings.makeServer()
			try preferences.addOrUpdate(server: server)
			try session.setServer(server)

			if isPresented {
				router.dismissSheet(withParent: true)
			} else {
				router.popToRoot()
			}
		} catch let error as ServerSettingsError {
			router.presentError(.serverSettings(error))
		} catch let error as AppPreferences.Error {
			router.presentError(.preferences(error))
		} catch let error as Session.Error {
			router.presentError(.session(error))
		} catch {
			fatalError("Unhandled error: \(error)")
		}
	}
}
