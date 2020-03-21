import Foundation
@testable import Magnesium

extension Server {
    static func mock(_ type: ServerType) -> Server {
        switch type {
        case .deluge:
            return Server(
                name: "MockServer",
                type: .deluge,
                data: try! JSONEncoder().encode(DelugeServerSettings(url: URL(string: "http://mock.mock")!)),
                keychainData: try! JSONEncoder().encode(DelugeKeychainData(password: "mockpassword"))
            )
        case .transmission:
            return Server(
                name: "MockServer",
                type: .transmission,
                data: try! JSONEncoder().encode(TransmissionServerSettings(
                    url: URL(string: "http://mock.mock")!,
                    username: "mockusername"
                )),
                keychainData: try! JSONEncoder().encode(TransmissionKeychainData(password: "mockpassword"))
            )
        }
    }
}
