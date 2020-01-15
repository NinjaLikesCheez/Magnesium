//
//  DefaultDelugeSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Navigator
import Preferences

final class DefaultDelugeSettingsViewModel: DelugeSettingsViewModel {
    private let navigator: Navigator
    private let preferences: Preferences
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private var observers = [AnyCancellable]()

    var title: String {
        return "Add Server"
    }

    var saveButtonTitle: String {
        return "Add"
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

    // swiftlint:disable identifier_name
    let _nameViewModel = DefaultTextInputTableViewCellViewModel(
        name: "name",
        placeholder: "Deluge",
        value: CurrentValueSubject(nil),
        returnKeyType: .next
    )

    let _serverViewModel = DefaultTextInputTableViewCellViewModel(
        name: "server",
        placeholder: "https://example.com",
        value: CurrentValueSubject(nil),
        keyboardType: .URL,
        returnKeyType: .next,
        autocapitalizationType: .none
    )

    let _passwordViewModel = DefaultTextInputTableViewCellViewModel(
        name: "password",
        placeholder: "password",
        value: CurrentValueSubject(nil),
        isSecure: true,
        returnKeyType: .send
    )
    // swiftlint:enable identifier_name

    var nameViewModel: TextInputTableViewCellViewModel {
        return _nameViewModel
    }

    var serverViewModel: TextInputTableViewCellViewModel {
        return _serverViewModel
    }

    var passwordViewModel: TextInputTableViewCellViewModel {
        return _passwordViewModel
    }

    init(navigator: Navigator, preferences: Preferences) {
        self.navigator = navigator
        self.preferences = preferences
        nameViewModel.value
            .combineLatest(serverViewModel.value, passwordViewModel.value)
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

        for viewModel in [_nameViewModel, _serverViewModel, _passwordViewModel] {
            isLoadingSubject
                .map { !$0 }
                .assign(to: \.value, on: viewModel.isEnabledSubject)
                .store(in: &observers)
        }
    }

    func didSelectSave() {
        guard isSaveButtonEnabledSubject.value,
            let name = nameViewModel.value.value,
            let url = serverViewModel.value.value.flatMap({ URL(string: $0) }),
            let password = passwordViewModel.value.value
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
                        self?.preferences.addOrUpdate(server: Server(
                            name: name,
                            type: .deluge,
                            data: try JSONEncoder().encode(settings)
                        ))
                        self?.navigator.popToRoot(animated: true)
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

    private func displayError(_ error: DelugeClientError) {
        let message: String
        switch error {
        case .unauthenticated:
            message = "Ensure your server URL and password are correct."
        default:
            message = error.localizedDescription
        }

        var alert = AlertModel(
            title: "Authentication Failed",
            message: message,
            style: .alert
        )
        alert.actions.append(AlertActionModel(title: "OK", style: .default, handler: nil))
        navigator.present(AlertScreen(alert), animated: true)
    }

    private func displayError(_ error: Error, title: String) {
        var alert = AlertModel(
            title: title,
            message: error.localizedDescription,
            style: .alert
        )
        alert.actions.append(AlertActionModel(title: "OK", style: .default, handler: nil))
        navigator.present(AlertScreen(alert), animated: true)
    }
}
