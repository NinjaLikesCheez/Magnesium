//
//  QBittorrentServerView.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import SwiftUI

struct AddQBittorrentServerView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(Session.self) private var session
	@Environment(AppPreferences.self) private var preferences

	@State private var settings: QBittorrentSettings = .init()
	@State private var showBasicAuthentication = false
	@State private var isSaving = false
	@State private var showingError = false
	@State private var errorMessage: String = ""

	var body: some View {
		Form {
			ServerSettingsSection(name: $settings.name, address: $settings.address) {
				TextField("Username", text: $settings.username.projectedValue)
					.autocorrectionDisabled()
					.autocapitalization(.none)

				SecureField("Password", text: $settings.password.projectedValue)
					.textContentType(.password)
					.autocorrectionDisabled()
					.autocapitalization(.none)
			}

			BasicAuthenticationSection(basicAuthentication: $settings.basicAuthentication)
		}
		.toolbar {
			saveButton
		}
		.alert("Error", isPresented: $showingError) {
			Button("OK", role: .cancel) {}
		} message: {
			Text(errorMessage)
		}
		.navigationTitle("Deluge Settings")
	}

	var saveButton: some View {
		Button {
			isSaving = true
			Task {
				do {
					let server = try await settings.makeServer()
					try preferences.addOrUpdate(server: server)
					session.setServer(server)
					dismiss()
				} catch let error as ServerSettingsItem.Error {
					switch error {
					case .invalidState(let message):
						errorMessage = message
						showingError = true
					case .unableToAuthenticate:
						errorMessage = "Unable to authenticate. Please check the settings are correct."
						showingError = true
					}
				} catch {
					errorMessage = "An unknown error occurred. Please try again. \(error.localizedDescription)"
					showingError = true
				}
				isSaving = false
			}
		} label: {
			if isSaving {
				ProgressView()
			} else {
				Text("Save")
			}
		}
		.disabled(!saveButtonEnabled)
	}

	var saveButtonEnabled: Bool {
		!settings.name.isEmpty && !settings.address.isEmpty && URL(string: settings.address) != nil && !settings.password.isEmpty
		&& (!showBasicAuthentication
					|| !settings.basicAuthentication.username.isEmpty && !settings.basicAuthentication.password.isEmpty)
	}
}
