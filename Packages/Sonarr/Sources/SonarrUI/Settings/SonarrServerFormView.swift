import SonarrCore
import SwiftUI

/// A reusable form for entering/editing Sonarr connection details.
///
/// Sonarr has exactly one API, so — unlike Torrent's `AddServerView`/per-backend-type screens —
/// there's no "pick a server type" step; this is the only add/edit form the feature needs.
struct SonarrServerFormView: View {
	@Binding var name: String
	@Binding var address: String
	@Binding var apiKey: String

	let onSave: () -> Void
	let saveButtonEnabled: Bool
	let isSaving: Bool

	var body: some View {
		Form {
			Section("Server") {
				TextField("Name", text: $name)
					#if !os(macOS)
						.autocapitalization(.words)
					#endif

				TextField("Address", text: $address)
					.textContentType(.URL)
					.autocorrectionDisabled()
					#if !os(macOS)
						.autocapitalization(.none)
						.keyboardType(.URL)
					#endif
			}

			Section {
				SecureField("API Key", text: $apiKey)
					.autocorrectionDisabled()
					#if !os(macOS)
						.autocapitalization(.none)
					#endif
			} footer: {
				Text("Found under Settings → General → Security → API Key")
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button(action: onSave) {
					if isSaving {
						ProgressView()
					} else {
						Text("Save")
					}
				}
				.disabled(!saveButtonEnabled)
			}
		}
	}
}
