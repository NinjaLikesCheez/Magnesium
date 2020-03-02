//
//  AddFileFlow.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

final class AddFileFlow {
    private let viewController: UIViewController
    private let session: Session
    private var observers = [AnyCancellable]()

    init(viewController: UIViewController, session: Session) {
        self.viewController = viewController
        self.session = session
    }

    func addFile(at url: URL) {
        guard let server = session.server else {
            showError(title: "Unable to Add Torrent", message: "There is no currently selected server.")
            return
        }

        var isAccessingSecurityScopedResource = false
        if !FileManager.default.isReadableFile(atPath: url.absoluteString) {
            _ = url.startAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = true
        }

        defer {
            if isAccessingSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        switch server.type {
        case .deluge:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(DelugeServerSettings.self, from: server.data),
                let keychain = server.keychainData.flatMap({
                    try? decoder.decode(DelugeKeychainData.self, from: $0)
                })
            else {
                showError(title: "Unable to Add Torrent", message: "The server settings could not be read.")
                return
            }

            let client = DefaultDelugeClient(
                baseURL: settings.url,
                password: keychain.password
            )
            client.request(.add(fileURL: url))
                .ui()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: "Failed to Add Torrent", message: error.localizedDescription)
                }, receiveValue: { _ in })
                .store(in: &observers)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: server.data),
                let keychain = server.keychainData.flatMap({
                    try? decoder.decode(TransmissionKeychainData.self, from: $0)
                })
            else {
                showError(title: "Unable to Add Torrent", message: "The server settings could not be read.")
                return
            }

            let client = DefaultTransmissionClient(
                baseURL: settings.url,
                username: settings.username,
                password: keychain.password
            )
            client.add(fileURL: url)
                .ui()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: "Failed to Add Torrent", message: error.localizedDescription)
                }, receiveValue: { _ in })
                .store(in: &observers)
        }
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(title: title, message: message, style: .alert)
        alert.addAction(AlertAction(title: "OK", style: .default))
        var current = viewController
        while let next = current.presentedViewController {
            current = next
        }
        current.present(alert.createAlertController(), animated: true)
    }
}
