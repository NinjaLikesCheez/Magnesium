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

final class TransmissionSettingsViewModel: ServerSettingsViewModel {
    private weak var coordinator: ServerSettingsCoordinator?
    private let preferences: Preferences
    private let server: Server?
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private var observers = [AnyCancellable]()

    private lazy var settings: TransmissionServerSettings? = {
        return (server?.data).flatMap { data in
            try? JSONDecoder().decode(TransmissionServerSettings.self, from: data)
        }
    }()

    private lazy var nameValue: CurrentValueSubject<String?, Never> = {
        return CurrentValueSubject(server?.name)
    }()

    private lazy var nameEnabled: CurrentValueSubject<Bool, Never> = {
        return CurrentValueSubject(true)
    }()

    private lazy var nameViewModel: DefaultTextInputTableViewCellViewModel = {
        return DefaultTextInputTableViewCellViewModel(
            name: "name",
            placeholder: "Transmission",
            value: nameValue,
            isEnabled: nameEnabled.eraseToAnyPublisher(),
            returnKeyType: .next
        )
    }()

    private lazy var serverValue: CurrentValueSubject<String?, Never> = {
        return CurrentValueSubject(settings?.url.absoluteString)
    }()

    private lazy var serverEnabled: CurrentValueSubject<Bool, Never> = {
        return CurrentValueSubject(true)
    }()

    private lazy var serverViewModel: DefaultTextInputTableViewCellViewModel = {
        return DefaultTextInputTableViewCellViewModel(
            name: "server",
            placeholder: "https://example.com",
            value: serverValue,
            isEnabled: serverEnabled.eraseToAnyPublisher(),
            keyboardType: .URL,
            returnKeyType: .next,
            autocapitalizationType: .none
        )
    }()

    private lazy var usernameValue: CurrentValueSubject<String?, Never> = {
        return CurrentValueSubject(settings?.authentication?.username)
    }()

    private lazy var usernameEnabled: CurrentValueSubject<Bool, Never> = {
        return CurrentValueSubject(true)
    }()

    private lazy var usernameViewModel: DefaultTextInputTableViewCellViewModel = {
        return DefaultTextInputTableViewCellViewModel(
            name: "username",
            placeholder: "user (optional)",
            value: usernameValue,
            isEnabled: usernameEnabled.eraseToAnyPublisher(),
            isSecure: true,
            returnKeyType: .next,
            autocapitalizationType: .none
        )
    }()

    private lazy var passwordValue: CurrentValueSubject<String?, Never> = {
        return CurrentValueSubject(settings?.authentication?.password)
    }()

    private lazy var passwordEnabled: CurrentValueSubject<Bool, Never> = {
        return CurrentValueSubject(true)
    }()

    private lazy var passwordViewModel: DefaultTextInputTableViewCellViewModel = {
        return DefaultTextInputTableViewCellViewModel(
            name: "password",
            placeholder: "password (optional)",
            value: passwordValue,
            isEnabled: passwordEnabled.eraseToAnyPublisher(),
            isSecure: true,
            returnKeyType: .send
        )
    }()

    var title: String {
        return server == nil ? "Add Server" : "Edit Server"
    }

    var saveButtonTitle: String {
        return server == nil ? "Add" : "Save"
    }

    var canDelete: Bool {
        return server != nil
    }

    var isLoading: AnyPublisher<Bool, Never> {
        return isLoadingSubject
            .ui()
            .eraseToAnyPublisher()
    }

    var isSaveButtonEnabled: AnyPublisher<Bool, Never> {
        return isSaveButtonEnabledSubject
            .ui()
            .eraseToAnyPublisher()
    }

    var inputs: [TextInputTableViewCellViewModel] {
        return [nameViewModel, serverViewModel, usernameViewModel, passwordViewModel]
    }

    init(coordinator: ServerSettingsCoordinator, preferences: Preferences, server: Server? = nil) {
        self.coordinator = coordinator
        self.preferences = preferences
        self.server = server
        nameValue
            .combineLatest(serverValue)
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

    func didSelectSave() {
        guard isSaveButtonEnabledSubject.value,
            let name = nameValue.value,
            let url = serverValue.value.flatMap({ URL(string: $0) })
        else {
            return
        }

        var authentication: TransmissionClient.Authentication?
        if let username = usernameValue.value, let password = passwordValue.value {
            authentication = TransmissionClient.Authentication(username: username, password: password)
        }

        isLoadingSubject.send(true)
        let client = TransmissionClient(baseURL: url, authentication: authentication)
        client.getTorrents() // TODO: use simple auth methods
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    do {
                        let settings = TransmissionServerSettings(
                            url: url,
                            authentication: authentication.map {
                                TransmissionServerSettings.Authentication(username: $0.username, password: $0.password)
                            }
                        )
                        try self?.saveServer(name: name, settings: settings)
                    } catch {
                        self?.displayError(error, title: "Unable to Add Server")
                    }
                case let .failure(error):
                    self?.displayError(error)
                }
                self?.isLoadingSubject.send(false)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func saveServer(name: String, settings: TransmissionServerSettings) throws {
        let data = try JSONEncoder().encode(settings)
        if var server = server {
            server.name = name
            server.data = data
            preferences.addOrUpdate(server: server)
        } else {
            preferences.addOrUpdate(server: Server(name: name, type: .transmission, data: data))
        }
        coordinator?.complete()
    }

    func didSelectDelete(from source: PopoverSource) {
        var alert = Alert(title: nil, message: "Are you sure you want to delete this server?", style: .actionSheet)
        alert.actions.append(AlertAction(title: "Delete Server", style: .destructive, handler: { [weak self] in
            guard let server = self?.server else { return }
            self?.preferences.remove(server: server)
            self?.coordinator?.complete()
        }))
        alert.actions.append(AlertAction(title: "Cancel", style: .cancel, handler: nil))
        coordinator?.showAlert(alert, from: source)
    }

    private func displayError(_ error: TransmissionClientError) {
        let message: String
        switch error {
        case .unauthenticated:
            message = "Ensure your username and password are correct."
        default:
            message = error.localizedDescription
        }

        var alert = Alert(
            title: "Authentication Failed",
            message: message,
            style: .alert
        )
        alert.actions.append(AlertAction(title: "OK", style: .default, handler: nil))
        coordinator?.showAlert(alert)
    }

    private func displayError(_ error: Error, title: String) {
        var alert = Alert(
            title: title,
            message: error.localizedDescription,
            style: .alert
        )
        alert.actions.append(AlertAction(title: "OK", style: .default, handler: nil))
        coordinator?.showAlert(alert)
    }
}
