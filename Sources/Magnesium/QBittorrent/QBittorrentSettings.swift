//
//  QBittorrentSettings.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//

import QBittorrent
import Foundation
import Observation
import TorrentUI

@Observable
class QBittorrentSettings {
	var name: String
	var address: String
	var username: String
	var password: String
	var basicAuthentication: ServerBasicAuthentication

	init(name: String, address: String, username: String, password: String, basicAuthentication: ServerBasicAuthentication) {
		self.name = name
		self.address = address
		self.username = username
		self.password = password
		self.basicAuthentication = basicAuthentication
	}

	init() {
		self.name = ""
		self.address = ""
		self.username = ""
		self.password = ""
		self.basicAuthentication = .init()
	}

	func makeServer() async throws(ServerSettingsError) -> TorrentServer {
		fatalError("Not implemented")
	}
}
