import Foundation
import Preferences

extension Server {
    func listViewModel() -> AnyTorrentListViewModel? {
        switch type {
        case .deluge:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(DelugeServerSettings.self, from: data),
                let keychainData = keychainData,
                let keychain = try? decoder.decode(DelugeKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = DefaultDelugeClient(
                baseURL: settings.url,
                password: keychain.password
            )
            let implementation = DelugeTorrentListViewModelImplementation(client: client)
            let viewModel = StandardTorrentListViewModel(implementation: implementation, server: self)
            return AnyTorrentListViewModel(viewModel)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: data),
                let keychainData = keychainData,
                let keychain = try? decoder.decode(TransmissionKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = DefaultTransmissionClient(
                baseURL: settings.url,
                username: settings.username,
                password: keychain.password
            )
            let implementation = TransmissionTorrentListViewModelImplementation(client: client)
            let viewModel = StandardTorrentListViewModel(implementation: implementation, server: self)
            return AnyTorrentListViewModel(viewModel)
        }
    }
}
