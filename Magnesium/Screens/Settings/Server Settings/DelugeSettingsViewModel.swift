//
//  DelugeSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences

final class DelugeSettingsViewModel: ViewModel, EventProducer {
    private let preferences: Preferences
    private let server: Server?
    private let eventSubject = PassthroughSubject<ServerSettingsEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let nameSubject: CurrentValueSubject<String?, Never>
    private let serverSubject: CurrentValueSubject<String?, Never>
    private let passwordSubject: CurrentValueSubject<String?, Never>
    private var observers = [AnyCancellable]()
    let state: ServerSettingsViewState

    var events: AnyPublisher<ServerSettingsEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences, server: Server? = nil) {
        self.preferences = preferences
        self.server = server

        let settings = (server?.data).flatMap { data in
            try? JSONDecoder().decode(DelugeServerSettings.self, from: data)
        }

        let keychain = (server?.keychainData).flatMap { data in
            try? JSONDecoder().decode(DelugeKeychainData.self, from: data)
        }

        nameSubject = CurrentValueSubject(server?.name)
        serverSubject = CurrentValueSubject(settings?.url.absoluteString)
        passwordSubject = CurrentValueSubject(keychain?.password)

        let nameEnabled = CurrentValueSubject<Bool, Never>(true)
        let nameInput = DefaultTextInputTableViewCellViewModel(
            name: "name",
            placeholder: "Deluge",
            value: nameSubject,
            isEnabled: nameEnabled.eraseToAnyPublisher(),
            returnKeyType: .next
        )

        let serverEnabled = CurrentValueSubject<Bool, Never>(true)
        let serverInput = DefaultTextInputTableViewCellViewModel(
            name: "server",
            placeholder: "https://example.com",
            value: serverSubject,
            isEnabled: serverEnabled.eraseToAnyPublisher(),
            keyboardType: .URL,
            returnKeyType: .next,
            autocapitalizationType: .none,
            autocorrectionType: .no,
            textContentType: .URL
        )

        let passwordEnabled = CurrentValueSubject<Bool, Never>(true)
        let passwordInput = DefaultTextInputTableViewCellViewModel(
            name: "password",
            placeholder: "password",
            value: passwordSubject,
            isEnabled: passwordEnabled.eraseToAnyPublisher(),
            isSecure: true,
            returnKeyType: .send
        )

        state = ServerSettingsViewState(
            title: server == nil ? "Add Server" : "Edit Server",
            saveButtonTitle: server == nil ? "Add" : "Save",
            canDelete: server != nil,
            isLoading: isLoadingSubject.ui().eraseToAnyPublisher(),
            isSaveButtonEnabled: isSaveButtonEnabledSubject.eraseToAnyPublisher(),
            inputs: [nameInput, serverInput, passwordInput]
        )

        nameSubject
            .combineLatest(serverSubject, passwordSubject)
            .map { name, server, password in
                guard
                    let name = name,
                    let server = server,
                    let serverURL = URL(string: server),
                    let password = password
                else {
                    return false
                }
                return !name.isEmpty
                    && ["http", "https"].contains(serverURL.scheme) && serverURL.host != nil
                    && !password.isEmpty
            }
            .removeDuplicates()
            .assign(to: \.value, on: isSaveButtonEnabledSubject)
            .store(in: &observers)

        for subject in [nameEnabled, serverEnabled, passwordEnabled] {
            isLoadingSubject
                .map { !$0 }
                .assign(to: \.value, on: subject)
                .store(in: &observers)
        }
    }

    func handle(_ event: ServerSettingsViewEvent) {
        switch event {
        case .save:
            handleSave()
        case let .delete(source):
            handleDelete(source: source)
        }
    }

    private func handleSave() {
        guard isSaveButtonEnabledSubject.value,
            let name = nameSubject.value,
            let url = serverSubject.value.flatMap({ URL(string: $0) }),
            let password = passwordSubject.value
        else {
            return
        }

        isLoadingSubject.send(true)
        let client = DefaultDelugeClient(baseURL: url, password: password)
        client.authenticate()
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    do {
                        let settings = DelugeServerSettings(url: url)
                        let keychain = DelugeKeychainData(password: password)
                        try self?.saveServer(name: name, settings: settings, keychain: keychain)
                    } catch {
                        self?.showError(title: "Unable to Add Server", message: error.localizedDescription)
                    }
                case let .failure(error):
                    self?.showError(error)
                }
                self?.isLoadingSubject.send(false)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func saveServer(name: String, settings: DelugeServerSettings, keychain: DelugeKeychainData) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        let keychainData = try encoder.encode(keychain)
        if var server = server {
            server.name = name
            server.data = data
            server.keychainData = keychainData
            preferences.addOrUpdate(server: server)
        } else {
            preferences.addOrUpdate(server: Server(
                name: name,
                type: .deluge,
                data: data,
                keychainData: keychainData
            ))
        }
        eventSubject.send(.complete)
    }

    private func handleDelete(source: PopoverSource) {
        guard let server = server else { return }
        var alert = Alert(title: nil, message: "Are you sure you want to delete this server?", style: .actionSheet)
        alert.addAction(AlertAction(title: "Delete Server", style: .destructive) {
            self.preferences.remove(server: server)
            self.eventSubject.send(.complete)
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func showError(_ error: DelugeError) {
        let message: String
        switch error {
        case .unauthenticated:
            message = "Ensure your password is correct."
        default:
            message = error.localizedDescription
        }

        showError(title: "Authentication Failed", message: message)
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(AlertAction(title: "OK", style: .default))
        eventSubject.send(.alert(alert, source: nil))
    }
}
