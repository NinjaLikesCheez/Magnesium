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
            let client = Current.deluge(settings.url, keychain.password)
            let implementation = DelugeTorrentListViewModelImplementation(client: client)
            let viewModel = StandardTorrentListViewModel(implementation: implementation, server: self)
            return .init(viewModel)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: data),
                let keychainData = keychainData,
                let keychain = try? decoder.decode(TransmissionKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = Current.transmission(settings.url, settings.username, keychain.password)
            let implementation = TransmissionTorrentListViewModelImplementation(client: client)
            let viewModel = StandardTorrentListViewModel(implementation: implementation, server: self)
            return .init(viewModel)
        }
    }
}
