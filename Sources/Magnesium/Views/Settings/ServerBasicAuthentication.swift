import Deluge
import Observation

@Observable
class ServerBasicAuthentication {
	var username: String = ""
	var password: String = ""

	init(username: String? = nil, password: String? = nil) {
		self.username = username ?? ""
		self.password = password ?? ""
	}

	func toAPIClient() -> BasicAuthentication? {
		guard !username.isEmpty && !password.isEmpty else {
			return nil
		}

		return .init(username: username, password: password)
	}
}

extension BasicAuthentication {
	func toServerBasicAuthentication() -> ServerBasicAuthentication {
		ServerBasicAuthentication(username: username, password: password)
	}
}
