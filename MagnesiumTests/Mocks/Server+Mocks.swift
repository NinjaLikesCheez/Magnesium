import Foundation
@testable import Magnesium

// swiftlint:disable force_try
extension Server {
    static func delugeMock(name: String = "Server") -> Server {
        return Server(
            name: name,
            type: .deluge,
            data: try! JSONEncoder().encode(DelugeServerSettings(url: URL(string: "http://localhost")!)),
            keychainData: try! JSONEncoder().encode(DelugeKeychainData(password: ""))
        )
    }

    static func transmissionMock(name: String = "Server") -> Server {
        return Server(
            name: name,
            type: .transmission,
            data: try! JSONEncoder().encode(TransmissionServerSettings(
                url: URL(string: "http://localhost")!,
                username: nil
            )),
            keychainData: try! JSONEncoder().encode(TransmissionKeychainData())
        )
    }
}
