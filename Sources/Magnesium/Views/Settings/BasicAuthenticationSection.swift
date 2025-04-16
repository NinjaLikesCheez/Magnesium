//
//  BasicAuthenticationSection.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//
import SwiftUI

struct BasicAuthenticationSection: View {
	@Binding var basicAuthentication: ServerBasicAuthentication
	@State private var showBasicAuthentication: Bool = false

	var body: some View {
		Section {
			Toggle(isOn: $showBasicAuthentication) {
				Text("Enable Basic Authentication")
			}

			if showBasicAuthentication {
				TextField("Username", text: $basicAuthentication.username)
					.textContentType(.username)
					.autocorrectionDisabled()
					.autocapitalization(.none)

				SecureField("Password", text: $basicAuthentication.password)
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
}
