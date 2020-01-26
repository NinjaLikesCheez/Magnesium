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

final class DelugeSettingsViewModel: ServerSettingsViewModel {
    private let preferences: Preferences
    private let server: Server?
    private let eventSubject = PassthroughSubject<ServerSettingsEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private var observers = [AnyCancellable]()

    private lazy var settings: DelugeServerSettings? = {
        return (server?.data).flatMap { data in
            try? JSONDecoder().decode(DelugeServerSettings.self, from: data)
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
            placeholder: "Deluge",
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
            autocapitalizationType: .none,
            textContentType: .URL
        )
    }()

    private lazy var passwordValue: CurrentValueSubject<String?, Never> = {
        return CurrentValueSubject(settings?.password)
    }()

    private lazy var passwordEnabled: CurrentValueSubject<Bool, Never> = {
        return CurrentValueSubject(true)
    }()

    private lazy var passwordViewModel: DefaultTextInputTableViewCellViewModel = {
        return DefaultTextInputTableViewCellViewModel(
            name: "password",
            placeholder: "password",
            value: passwordValue,
            isEnabled: passwordEnabled.eraseToAnyPublisher(),
            isSecure: true,
            returnKeyType: .send
        )
    }()

    var events: AnyPublisher<ServerSettingsEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

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
        return [nameViewModel, serverViewModel, passwordViewModel]
    }

    init(preferences: Preferences, server: Server? = nil) {
        self.preferences = preferences
        self.server = server
        nameValue
            .combineLatest(serverValue, passwordValue)
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

    func didSelectSave() {
        guard isSaveButtonEnabledSubject.value,
            let name = nameValue.value,
            let url = serverValue.value.flatMap({ URL(string: $0) }),
            let password = passwordValue.value
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
                        let settings = DelugeServerSettings(url: url, password: password)
                        try self?.saveServer(name: name, settings: settings)
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

    private func saveServer(name: String, settings: DelugeServerSettings) throws {
        let data = try JSONEncoder().encode(settings)
        if var server = server {
            server.name = name
            server.data = data
            preferences.addOrUpdate(server: server)
        } else {
            preferences.addOrUpdate(server: Server(name: name, type: .deluge, data: data))
        }
        eventSubject.send(.complete)
    }

    func didSelectDelete(from source: PopoverSource) {
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
