//
//  EditDelugeServerView.swift
//  Magnesium
//
//  Created by ninji on 16/04/2025.
//

import SwiftNavigation
import SwiftUI

struct EditDelugeServerView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(TorrentSession.self) private var session
	@Environment(TorrentPreferences.self) private var preferences

	@State private var error: Error?

	@State private var settings: DelugeSettings

	private let server: TorrentServer

	init(_ server: TorrentServer) {
		self.server = server
		// swiftlint:disable force_try
		// See https://github.com/NinjaLikesCheez/Magnesium/issues/30 — this should decode
		// failably and surface errors through the Error/panel mechanism instead of crashing.
		let serverSettings = try! JSONDecoder().decode(DelugeServerSettings.self, from: server.data)
		let keychain = try! JSONDecoder().decode(DelugeKeychainData.self, from: server.keychainData!)
		// swiftlint:enable force_try

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
					do throws(TorrentPreferences.Error) {
						try preferences.remove(server: server)
						dismiss()
					} catch {
						self.error = .preferences(error)
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

			dismiss()
		} catch let error as ServerSettingsError {
			self.error = .serverSettings(error)
		} catch let error as TorrentPreferences.Error {
			self.error = .preferences(error)
		} catch let error as TorrentSession.Error {
			self.error = .session(error)
		} catch {
			fatalError("Unhandled error: \(error)")
		}
	}
}

extension EditDelugeServerView {
	@CasePathable
	enum Error {
		case preferences(TorrentPreferences.Error)
		case serverSettings(ServerSettingsError)
		case session(TorrentSession.Error)
	}
}
