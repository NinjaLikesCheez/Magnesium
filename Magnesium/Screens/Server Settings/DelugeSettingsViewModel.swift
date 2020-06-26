import Combine
import CommonModels
import Deluge
import Foundation
import ViewModel

final class DelugeSettingsViewModel: ViewModel {
    private let server: Server?
    private let eventSubject = PassthroughSubject<ServerSettingsViewModelEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let nameSubject: CurrentValueSubject<String?, Never>
    private let serverSubject: CurrentValueSubject<String?, Never>
    private let passwordSubject: CurrentValueSubject<String?, Never>
    private var cancellables = Set<AnyCancellable>()
    let values: ServerSettingsViewValues

    var eventPublisher: AnyPublisher<ServerSettingsViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(server: Server? = nil) {
        self.server = server

        let settings = (server?.data).flatMap { data in
            try? JSONDecoder().decode(DelugeServerSettings.self, from: data)
        }

        let keychain = (server?.keychainData).flatMap { data in
            try? JSONDecoder().decode(DelugeKeychainData.self, from: data)
        }

        nameSubject = .init(server?.name)
        serverSubject = .init(settings?.url.absoluteString)
        passwordSubject = .init(keychain?.password)

        let nameEnabled = CurrentValueSubject<Bool, Never>(true)
        let nameInput = TextInputItem(
            name: L10n.Screen.EditServer.serverName,
            placeholder: L10n.Server.deluge,
            value: nameSubject,
            isEnabled: nameEnabled.ui().eraseToAnyPublisher(),
            configuration: TextInputItem.Configuration.default.withReturnKeyType(.next)
        )

        let serverEnabled = CurrentValueSubject<Bool, Never>(true)
        let serverInput = TextInputItem(
            name: L10n.Screen.EditServer.serverURL,
            placeholder: "https://example.com",
            value: serverSubject,
            isEnabled: serverEnabled.ui().eraseToAnyPublisher(),
            configuration: TextInputItem.Configuration.url.withReturnKeyType(.next)
        )

        let passwordEnabled = CurrentValueSubject<Bool, Never>(true)
        let passwordInput = TextInputItem(
            name: L10n.Screen.EditServer.password,
            placeholder: L10n.Screen.EditServer.optionalPasswordPlaceholder,
            value: passwordSubject,
            isEnabled: passwordEnabled.ui().eraseToAnyPublisher(),
            configuration: TextInputItem.Configuration.password.withReturnKeyType(.send)
        )

        values = .init(
            title: server == nil ? L10n.Screen.AddServer.title : L10n.Screen.EditServer.title,
            saveButtonTitle: server == nil ? L10n.Action.add : L10n.Action.save,
            canDelete: server != nil,
            isLoading: isLoadingSubject.ui().eraseToAnyPublisher(),
            isSaveButtonEnabled: isSaveButtonEnabledSubject.ui().eraseToAnyPublisher(),
            inputs: [nameInput, serverInput, passwordInput]
        )

        nameSubject
            .combineLatest(serverSubject, passwordSubject)
            .map { name, server, password in
                guard let name = name, let server = server, let password = password else { return false }
                return !name.isEmpty && !server.isEmpty && !password.isEmpty
            }
            .removeDuplicates()
            .assign(to: \.value, on: isSaveButtonEnabledSubject)
            .store(in: &cancellables)

        for subject in [nameEnabled, serverEnabled, passwordEnabled] {
            isLoadingSubject
                .map { !$0 }
                .assign(to: \.value, on: subject)
                .store(in: &cancellables)
        }
    }

    func send(_ event: ServerSettingsViewEvent) {
        switch event {
        case .saveSelected:
            handleSaveSelected()
        case let .deleteSelected(source):
            handleDeleteSelected(source: source)
        case .cancelSelected:
            eventSubject.send(.complete)
        }
    }

    private func handleSaveSelected() {
        guard isSaveButtonEnabledSubject.value,
              let name = nameSubject.value,
              let urlString = serverSubject.value,
              let password = passwordSubject.value
        else {
            return
        }

        guard let url = URL(string: urlString), ["http", "https"].contains(url.scheme), url.host != nil else {
            showError(title: L10n.Error.invalidURL, message: L10n.Screen.AddServer.invalidServerURL)
            return
        }

        isLoadingSubject.send(true)

        let client = Current.deluge(url, password)
        let errorTitle = server == nil ? L10n.Error.failedToAddServer : L10n.Error.failedToSaveServer
        client.request(.authenticate)
            .onMainThread()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    do {
                        let settings = DelugeServerSettings(url: url)
                        let keychain = DelugeKeychainData(password: password)
                        try self?.saveServer(name: name, settings: settings, keychain: keychain)
                    } catch {
                        self?.showError(title: errorTitle, message: error.localizedDescription)
                    }
                case let .failure(error):
                    self?.showError(error)
                }
                self?.isLoadingSubject.send(false)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func saveServer(name: String, settings: DelugeServerSettings, keychain: DelugeKeychainData) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        let keychainData = try encoder.encode(keychain)
        if var server = server {
            server.name = name
            server.data = data
            server.keychainData = keychainData
            try Current.preferences.addOrUpdate(server: server)
        } else {
            try Current.preferences.addOrUpdate(server: .init(
                name: name,
                type: .deluge,
                data: data,
                keychainData: keychainData
            ))
        }
        eventSubject.send(.complete)
    }

    private func handleDeleteSelected(source: PopoverSource) {
        guard let server = server else { return }
        eventSubject.send(.alert(.init(
            message: L10n.Screen.EditServer.deleteServerConfirmation,
            style: .actionSheet(source),
            actions: [
                .init(title: L10n.Action.deleteServer, style: .destructive) {
                    do {
                        try Current.preferences.remove(server: server)
                    } catch {
                        self.showError(title: L10n.Error.failedToDeleteServer, message: error.localizedDescription)
                        return
                    }

                    self.eventSubject.send(.complete)
                },
                .cancel,
            ]
        )))
    }

    private func showError(_ error: DelugeError) {
        let message: String
        switch error {
        case .unauthenticated:
            message = L10n.Error.unauthenticatedVerifyCredentials
        default:
            message = error.localizedDescription
        }

        showError(title: L10n.Error.authenticationFailed, message: message)
    }

    private func showError(title: String, message: String?) {
        eventSubject.send(.alert(.init(title: title, message: message, style: .alert, action: .ok)))
    }
}
