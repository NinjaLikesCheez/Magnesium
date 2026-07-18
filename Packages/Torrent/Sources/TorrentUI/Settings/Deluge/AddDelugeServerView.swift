//
//  AddDelugeServerView.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//
import CommonUI
import Observation
import SwiftUI
import SwiftUINavigation

struct AddDelugeServerView: View {
	@Environment(TorrentPreferences.self) private var preferences
	@Environment(\.dismiss) var dismiss

	@State private var model = Model()
	@State private var settings = DelugeSettings()

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
					#if !os(macOS)
						.autocapitalization(.none)
					#endif
			},
			additionalSections: {}
		)
		.panel(item: $model.error) { error in
			switch error {
			case let .serverSettings(error):
				ErrorPanelCard(error: error) {
					model.error = nil
				}
			}

		}
		.navigationTitle("Deluge Settings")
	}

	private func save() async {
		do throws(ServerSettingsError) {
			let server = try await settings.makeServer()

			do {
				try preferences.addOrUpdate(server: server)
			} catch {
				switch error {
				case let .keychain(error):
					switch error {
					case let .system(status):
						let error = NSError.init(domain: NSOSStatusErrorDomain, code: Int(status))
						throw .keychain(message: "Keychain error: \(error.localizedDescription)")
					case .unknown:
						throw .keychain(message: "Couldn't save server settings to keychain")
					}
				}
			}

			dismiss()
		} catch {
			model.error = .serverSettings(error)
		}
	}
}

extension AddDelugeServerView {
	@Observable
	final class Model {
		init() {}

		var error: Error?

		@CasePathable
		enum Error: Hashable, Identifiable {
			case serverSettings(ServerSettingsError)

			var id: Self { self }
		}
	}
}
