//
//  AddDelugeServerView.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import Router
import SwiftUI
import Torrent

struct AddDelugeServerView<Router: RouterProtocol>: View {
	@Environment(Router.self) var router
	@Environment(TorrentPreferences.self) private var preferences
	@Environment(\.isPresented) private var isPresented

	@State private var settings: DelugeSettings = .init()

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

			if isPresented {
				router.dismissSheet(withParent: true)
			} else {
				router.pop()
			}
		} catch {
			if let router = router as? OnboardingRouter {
				router.presentError(.addServerError(error))
			} else if let router = router as? SettingsRouter {
				router.presentError(.serverSettings(error))
			}
		}
	}
}
