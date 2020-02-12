//
//  TransmissionSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

protocol TransmissionClientProvider {
    func createClient(baseURL: URL, username: String?, password: String?) -> TransmissionClient
}

struct DefaultTransmissionClientProvider: TransmissionClientProvider {
    func createClient(baseURL: URL, username: String?, password: String?) -> TransmissionClient {
        return DefaultTransmissionClient(baseURL: baseURL, username: username, password: password)
    }
}

final class TransmissionSettingsViewModel: ViewModel, EventEmitter {
    private let preferences: Preferences
    private let server: Server?
    private let clientProvider: TransmissionClientProvider
    private let eventSubject = PassthroughSubject<ServerSettingsEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let nameSubject: CurrentValueSubject<String?, Never>
    private let serverSubject: CurrentValueSubject<String?, Never>
    private let usernameSubject: CurrentValueSubject<String?, Never>
    private let passwordSubject: CurrentValueSubject<String?, Never>
    private var observers = [AnyCancellable]()
    let state: ServerSettingsViewState

    var events: AnyPublisher<ServerSettingsEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(
        preferences: Preferences,
        server: Server? = nil,
        clientProvider: TransmissionClientProvider = DefaultTransmissionClientProvider()
    ) {
        self.preferences = preferences
        self.server = server
        self.clientProvider = clientProvider

        let settings = (server?.data).flatMap { data in
            try? JSONDecoder().decode(TransmissionServerSettings.self, from: data)
        }

        let keychain = (server?.keychainData).flatMap { data in
            try? JSONDecoder().decode(TransmissionKeychainData.self, from: data)
        }

        nameSubject = CurrentValueSubject(server?.name)
        serverSubject = CurrentValueSubject(settings?.url.absoluteString)
        usernameSubject = CurrentValueSubject(settings?.username)
        passwordSubject = CurrentValueSubject(keychain?.password)

        let nameEnabled = CurrentValueSubject<Bool, Never>(true)
        let nameInput = TextInputTableViewCellViewState(
            name: NSLocalizedString("server_settings_option_name", comment: "name"),
            placeholder: NSLocalizedString("server_transmission", comment: "Transmission"),
            value: nameSubject,
            isEnabled: nameEnabled.eraseToAnyPublisher(),
            configuration: TextInputConfiguration.default.withReturnKeyType(.next)
        )

        let serverEnabled = CurrentValueSubject<Bool, Never>(true)
        let serverInput = TextInputTableViewCellViewState(
            name: NSLocalizedString("server_settings_option_server", comment: "server"),
            placeholder: "https://example.com",
            value: serverSubject,
            isEnabled: serverEnabled.eraseToAnyPublisher(),
            configuration: TextInputConfiguration.url.withReturnKeyType(.next)
        )

        let usernameEnabled = CurrentValueSubject<Bool, Never>(true)
        let usernameInput = TextInputTableViewCellViewState(
            name: NSLocalizedString("server_settings_option_username", comment: "username"),
            placeholder: NSLocalizedString("server_settings_option_username_hint_optional", comment: "user (optional)"),
            value: usernameSubject,
            isEnabled: usernameEnabled.eraseToAnyPublisher(),
            configuration: TextInputConfiguration.username.withReturnKeyType(.next)
        )

        let passwordEnabled = CurrentValueSubject<Bool, Never>(true)
        let passwordInput = TextInputTableViewCellViewState(
            name: NSLocalizedString("server_settings_option_password", comment: "password"),
            placeholder: NSLocalizedString(
                "server_settings_option_password_hint_optional",
                comment: "password (optional)"
            ),
            value: passwordSubject,
            isEnabled: passwordEnabled.eraseToAnyPublisher(),
            configuration: TextInputConfiguration.password.withReturnKeyType(.send)
        )

        let title: String
        let saveButtonTitle: String
        if server == nil {
            title = NSLocalizedString("server_settings_add_title", comment: "Add Server")
            saveButtonTitle = NSLocalizedString("action_add", comment: "Add")
        } else {
            title = NSLocalizedString("server_settings_edit_title", comment: "Edit Server")
            saveButtonTitle = NSLocalizedString("action_save", comment: "Save")
        }

        state = ServerSettingsViewState(
            title: title,
            saveButtonTitle: saveButtonTitle,
            canDelete: server != nil,
            isLoading: isLoadingSubject.ui().eraseToAnyPublisher(),
            isSaveButtonEnabled: isSaveButtonEnabledSubject.ui().eraseToAnyPublisher(),
            inputs: [nameInput, serverInput, usernameInput, passwordInput]
        )

        nameSubject
            .combineLatest(serverSubject)
            .map { name, server in
                guard
                    let name = name,
                    let server = server,
                    let serverURL = URL(string: server)
                else {
                    return false
                }
                return !name.isEmpty
                    && ["http", "https"].contains(serverURL.scheme) && serverURL.host != nil
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
            let url = serverSubject.value.flatMap({ URL(string: $0) })
        else {
            return
        }

        let username = usernameSubject.value
        let password = passwordSubject.value

        isLoadingSubject.send(true)
        let client = clientProvider.createClient(baseURL: url, username: username, password: password)
        client.authenticate()
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    do {
                        let settings = TransmissionServerSettings(url: url, username: username)
                        let keychain = TransmissionKeychainData(password: password)
                        try self?.saveServer(name: name, settings: settings, keychain: keychain)
                    } catch {
                        self?.showError(
                            title: NSLocalizedString("error_add_server", comment: "Unable to Add Server"),
                            message: error.localizedDescription
                        )
                    }
                case let .failure(error):
                    self?.showError(error)
                }
                self?.isLoadingSubject.send(false)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func saveServer(
        name: String,
        settings: TransmissionServerSettings,
        keychain: TransmissionKeychainData
    ) throws {
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
                type: .transmission,
                data: data,
                keychainData: keychainData
            ))
        }
        eventSubject.send(.complete)
    }

    private func handleDelete(source: PopoverSource) {
        guard let server = server else { return }
        var alert = Alert(
            title: nil,
            message: NSLocalizedString(
                "delete_server_confirmation",
                comment: "Are you sure you want to delete this server?"
            ),
            style: .actionSheet
        )
        alert.addAction(AlertAction(
            title: NSLocalizedString("action_delete_server", comment: "Delete Server"),
            style: .destructive,
            handler: {
                self.preferences.remove(server: server)
                self.eventSubject.send(.complete)
            }
        ))
        alert.addAction(.cancel())
        eventSubject.send(.alert(alert, source: source))
    }

    private func showError(_ error: TransmissionError) {
        let message: String
        switch error {
        case .unauthenticated:
            message = NSLocalizedString(
                "error_transmission_unauthenticated",
                comment: "Ensure your username and password are correct."
            )
        default:
            message = error.localizedDescription
        }

        showError(title: NSLocalizedString("error_authentication", comment: "Authentication Failed"), message: message)
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(.ok())
        eventSubject.send(.alert(alert, source: nil))
    }
}
