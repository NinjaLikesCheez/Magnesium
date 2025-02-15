import SwiftUI

struct ServerSettingsItem {
	let address: String
	let username: String?
	let password: String?
	let basicAuthentication: ServerBasicAuthentication?

	enum Error: Swift.Error {
		case invalidState(message: String)
		case unableToAuthenticate
	}
}

struct ServerSettingsView: View {
	@Binding var name: String
	@Binding var address: String
	var username: Binding<String>?
	var password: Binding<String>?
	var basicAuthentication: Binding<ServerBasicAuthentication>?

	@State private var showBasicAuthentication = false
	@State private var errorMessage: String?
	@State private var isSaving = false

	let saveServerAction: () async throws(ServerSettingsItem.Error) -> Void
	let saveServerButtonEnabled: (Bool) -> Bool

	var body: some View {
		Form {
			serverSettingsSection

			if let errorMessage {
				Text(errorMessage)
					.foregroundStyle(.red)
			}

			if let basicAuthentication {
				basicAuthenticationSection(basicAuthentication)
			}
		}
		.navigationTitle("Server Settings")
		.toolbar {
			saveButton
		}
	}

	var serverSettingsSection: some View {
		Section(header: Text("Server Settings")) {
			TextField("Name", text: $name)
				.textContentType(.name)

			TextField("URL", text: $address)
				.textContentType(.URL)
				.autocorrectionDisabled()
				.autocapitalization(.none)
				#if !os(macOS)
					.keyboardType(.URL)
				#endif
			if let username {
				TextField("Username", text: username.projectedValue)
					.textContentType(.username)
					.autocorrectionDisabled()
					.autocapitalization(.none)
			}

			if let password {
				SecureField("Password", text: password.projectedValue)
					.textContentType(.password)
					.autocorrectionDisabled()
					.autocapitalization(.none)
			}
		}
	}

	func basicAuthenticationSection(_ basicAuthentication: Binding<ServerBasicAuthentication>) -> some View {
		Section {
			Toggle(isOn: $showBasicAuthentication) {
				Text("Enable Basic Authentication")
			}

			if showBasicAuthentication {
				TextField("Username", text: basicAuthentication.username)
					.textContentType(.username)
					.autocorrectionDisabled()
					.autocapitalization(.none)

				SecureField("Password", text: basicAuthentication.password)
					.textContentType(.password)
					.autocorrectionDisabled()
					.autocapitalization(.none)
			}
		} header: {
			Text("Basic Authentication Settings")
		} footer: {
			Text("This is an additional layer of authentication that may be provided by your server.")
		}
	}

	var saveButton: some View {
		Button {
			Task {
				isSaving = true
				errorMessage = nil
				do throws(ServerSettingsItem.Error) {
					try await saveServerAction()
				} catch {
					switch error {
					case .invalidState(let message):
						errorMessage = message
					case .unableToAuthenticate:
						errorMessage = "Unable to authenticate. Please check the settings are correct."
					}
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
		.disabled(!saveServerButtonEnabled(showBasicAuthentication))
	}
}

#Preview {
	ServerSettingsView(
		name: .constant(""),
		address: .constant(""),
		username: .constant(""),
		password: .constant(""),
		basicAuthentication: .constant(.init()),
		saveServerAction: {},
		saveServerButtonEnabled: { basicAuthenicationEnabled in
			false
		}
	)
}
