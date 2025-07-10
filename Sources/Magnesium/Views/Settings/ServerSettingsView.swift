//
//  ServerSettingsView.swift
//  Magnesium
//
//  Created by ninji on 16/04/2025.
//

import SwiftUI

struct ServerSettingsView<FormContent: View, SectionContent: View>: View {
	let formContent: () -> FormContent
	let sectionContent: () -> SectionContent

	@State private var isSaving = false
	@State private var error: String? = nil

	@Binding var name: String
	@Binding var address: String
	@Binding var basicAuthentication: ServerBasicAuthentication

	let onSave: () -> Void
	let saveButtonEnabled: () -> Bool

	init(
		name: Binding<String>,
		address: Binding<String>,
		basicAuthentication: Binding<ServerBasicAuthentication>,
		onSave: @escaping ()-> Void,
		saveButtonEnabled: @escaping () -> Bool,
		@ViewBuilder additionalSettings: @escaping () -> FormContent,
		@ViewBuilder additionalSections: @escaping () -> SectionContent
	) {
		self._name = name
		self._address = address
		self._basicAuthentication = basicAuthentication
		self.onSave = onSave
		self.saveButtonEnabled = saveButtonEnabled
		self.formContent = additionalSettings
		self.sectionContent = additionalSections
	}

	var body: some View {
		Form {
			ServerSettingsSection(name: $name, address: $address, content: formContent)

			BasicAuthenticationSection(basicAuthentication: $basicAuthentication)

			sectionContent()
		}
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				saveButton
			}
		}
	}

	var saveButton: some View {
		Button(action: onSave) {
			if isSaving {
				ProgressView()
			} else {
				Text("Save")
			}
		}
		.disabled(!saveButtonEnabled())
	}
}

enum ServerSettingsError: Error, Equatable, Hashable {
	case invalidState(message: String)
	case unableToAuthenticate
	case request(message: String)
	case response(message: String)
	case keychain(message: String)
	case unknown(message: String)

	var title: String {
		switch self {
		case .invalidState:
			"Couldn't Add Server"
		case .unableToAuthenticate:
			"Couldn't Authenticate"
		case .request:
			"Request Error"
		case .response:
			"Response Error"
		case .keychain:
			"Couldn't Save Settings"
		case .unknown:
			"Unknown Error Occured"
		}
	}

	var systemName: String {
		switch self {
		case .invalidState:
			"nosign"
		case .unableToAuthenticate:
			"server.rack"
		case .request:
			"network.slash"
		case .response:
			"network.slash"
		case .unknown:
			"questionmark"
		case .keychain:
			"person.badge.key"
		}
	}

	var subtitle: String {
		switch self {
		case .invalidState(message: let message):
			message
		case .unableToAuthenticate:
			"Please check your settings and try again"
		case .request(message: let message):
			message
		case .response(message: let message):
			message
		case .keychain(message: let message):
			message
		case .unknown(message: let message):
			message
		}
	}
}
