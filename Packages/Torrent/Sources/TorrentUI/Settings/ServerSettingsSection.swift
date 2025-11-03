//
//  ServerSettingsSection.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import SwiftUI

struct ServerSettingsSection<Content: View>: View {
	@Binding var name: String
	@Binding var address: String
	let content: () -> Content

	init(name: Binding<String>, address: Binding<String>, @ViewBuilder content: @escaping () -> Content) {
		self._name = name
		self._address = address
		self.content = content
	}

	var body: some View {
		Section(header: Text("Server Settings")) {
			TextField("Name", text: $name)
				.textContentType(.name)

			TextField("URL", text: $address)
				.textContentType(.URL)
				.autocorrectionDisabled()
			#if !os(macOS)
				.autocapitalization(.none)
				.keyboardType(.URL)
			#endif

			content()
		}
	}
}
