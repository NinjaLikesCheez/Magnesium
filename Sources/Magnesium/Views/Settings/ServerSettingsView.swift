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
		onSave: @escaping () -> Void,
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
