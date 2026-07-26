import Common
import SonarrCore
import SonarrSession
import SwiftUI

/// Add/edit form for the single Sonarr server. Shared between `SonarrOnboardingFlow` and
/// `SonarrSettingsFlow` — since each hosts its own `Error` enum shape, this reports failures via
/// an `onError` closure rather than depending on either flow's `Model` directly.
struct AddSonarrServerView: View {
	@Environment(SonarrPreferences.self) private var preferences
	@Environment(\.dismiss) private var dismiss

	@State private var name: String = ""
	@State private var address: String = ""
	@State private var apiKey: String = ""
	@State private var isSaving = false

	let onError: (SonarrServerSettingsError) -> Void

	init(existing server: SonarrServer? = nil, onError: @escaping (SonarrServerSettingsError) -> Void) {
		self.onError = onError

		if let server {
			_name = State(initialValue: server.name)
			_address = State(initialValue: server.baseURL.absoluteString)
			_apiKey = State(initialValue: server.apiKey ?? "")
		}
	}

	var body: some View {
		SonarrServerFormView(
			name: $name,
			address: $address,
			apiKey: $apiKey,
			onSave: { Task { await save() } },
			saveButtonEnabled: isValid,
			isSaving: isSaving
		)
		.navigationTitle("Sonarr Settings")
	}

	private var isValid: Bool {
		!name.isEmpty && URL(string: address) != nil && !apiKey.isEmpty
	}

	private func save() async {
		isSaving = true
		defer { isSaving = false }

		guard let url = URL(string: address) else {
			onError(.invalidState(message: "Enter a valid server address"))
			return
		}

		let server = SonarrServer(name: name, baseURL: url, apiKey: apiKey)

		do throws(SonarrPreferences.Error) {
			try preferences.set(server: server)
			dismiss()
		} catch {
			switch error {
			case let .keychain(keychainError):
				onError(.keychain(message: keychainError.subtitle))
			}
		}
	}
}
