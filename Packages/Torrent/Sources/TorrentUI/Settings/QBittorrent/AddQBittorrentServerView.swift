//
//  QBittorrentServerView.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import SwiftUI
// TODO: this needs to be migrated to new navigation or ripped out

struct AddQBittorrentServerView: View {
	@Environment(TorrentSession.self) private var session
	@Environment(TorrentPreferences.self) private var preferences
	@Environment(\.dismiss) var dismiss

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
		.navigationTitle("QBittorrent Settings")
	}

	var saveButton: some View {
		Button {
			isSaving = true
			Task {
				do {
					let server = try await settings.makeServer()
					try preferences.addOrUpdate(server: server)
					try session.setServer(server)
					dismiss()
				} catch let error as ServerSettingsError {
					switch error {
					case .invalidState(let message):
						errorMessage = message
						showingError = true
					case .unableToAuthenticate:
						errorMessage = "Unable to authenticate. Please check the settings are correct."
						showingError = true
					case .request(message: let message):
						errorMessage = "Request could not be completed: \(message)"
					case .response(message: let message):
						errorMessage = "Response was unexpected: \(message)"
					case .keychain(message: let message):
						errorMessage = "Keychain save failed: \(message)"
					case .unknown(message: let message):
						errorMessage = "Unknown error occurred: \(message)"
					}
				} catch let error as TorrentSession.Error {
					switch error {
					case .missingKeychainData:
						errorMessage = "Missing keychain data. Please try again."
						showingError = true
					case .decodingFailed:
						errorMessage = "Failed to decode server settings. Please try again."
					case .notImplemented:
						errorMessage = "This feature is not implemented yet."
					}
					showingError = true
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
		!settings.name.isEmpty && !settings.address.isEmpty && URL(string: settings.address) != nil
			&& !settings.password.isEmpty
			&& (!showBasicAuthentication
				|| !settings.basicAuthentication.username.isEmpty && !settings.basicAuthentication.password.isEmpty)
	}
}
