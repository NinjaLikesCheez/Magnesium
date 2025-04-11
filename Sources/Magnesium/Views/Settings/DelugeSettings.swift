//
//  DelugeSettings.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import Observation

@Observable
class DelugeSettings {
	var name: String
	var address: String
	var password: String
	var basicAuthentication: ServerBasicAuthentication

	init(name: String, address: String, password: String, basicAuthentication: ServerBasicAuthentication) {
		self.name = name
		self.address = address
		self.password = password
		self.basicAuthentication = basicAuthentication
	}

	init() {
		self.name = ""
		self.address = ""
		self.password = ""
		self.basicAuthentication = .init()
	}
}
