import Combine
import Deluge
import Foundation
import Preferences
import ViewModel

final class DelugeSettingsViewModel: ViewModel {
    private let server: Server?
    private let eventSubject = PassthroughSubject<ServerSettingsEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let nameSubject: CurrentValueSubject<String?, Never>
    private let serverSubject: CurrentValueSubject<String?, Never>
    private let passwordSubject: CurrentValueSubject<String?, Never>
    private var cancellables = Set<AnyCancellable>()
    let state: ServerSettingsViewState

    var events: AnyPublisher<ServerSettingsEvent, Never> {
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

        nameSubject = CurrentValueSubject(server?.name)
        serverSubject = CurrentValueSubject(settings?.url.absoluteString)
        passwordSubject = CurrentValueSubject(keychain?.password)

        let nameEnabled = CurrentValueSubject<Bool, Never>(true)
        let nameInput = TextInputItem(
            name: L10n.serverSettingsOptionName,
            placeholder: L10n.deluge,
            value: nameSubject,
            isEnabled: nameEnabled.eraseToAnyPublisher(),
            configuration: TextInputItem.Configuration.default.withReturnKeyType(.next)
        )

        let serverEnabled = CurrentValueSubject<Bool, Never>(true)
        let serverInput = TextInputItem(
            name: L10n.serverSettingsOptionServer,
            placeholder: "https://example.com",
            value: serverSubject,
            isEnabled: serverEnabled.eraseToAnyPublisher(),
            configuration: TextInputItem.Configuration.url.withReturnKeyType(.next)
        )

        let passwordEnabled = CurrentValueSubject<Bool, Never>(true)
        let passwordInput = TextInputItem(
            name: L10n.serverSettingsOptionPassword,
            placeholder: L10n.serverSettingsOptionPasswordHint,
            value: passwordSubject,
            isEnabled: passwordEnabled.eraseToAnyPublisher(),
            configuration: TextInputItem.Configuration.password.withReturnKeyType(.send)
        )

        state = ServerSettingsViewState(
            title: server == nil ? L10n.addServerScreenTitle : L10n.editServerScreenTitle,
            saveButtonTitle: server == nil ? L10n.add : L10n.save,
            canDelete: server != nil,
            isLoading: isLoadingSubject.ui().eraseToAnyPublisher(),
            isSaveButtonEnabled: isSaveButtonEnabledSubject.eraseToAnyPublisher(),
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

    func handle(_ event: ServerSettingsViewEvent) {
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

        let errorTitle = server == nil ? L10n.addServerError : L10n.saveServerError

        guard let url = URL(string: urlString), ["http", "https"].contains(url.scheme), url.host != nil else {
            showError(title: errorTitle, message: L10n.serverURLValidationErrorDescription)
            return
        }

        isLoadingSubject.send(true)
        let client = Current.deluge(url, password)
        client.request(.authenticate)
            .ui()
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
            Current.preferences.addOrUpdate(server: server)
        } else {
            Current.preferences.addOrUpdate(server: Server(
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
        let alert = Alert(title: nil, message: L10n.deleteServerConfirmation, style: .actionSheet(source)) {
            AlertAction(title: L10n.deleteServer, style: .destructive) {
                Current.preferences.remove(server: server)
                self.eventSubject.send(.complete)
            }

            AlertAction.cancel
        }
        eventSubject.send(.alert(alert))
    }

    private func showError(_ error: DelugeError) {
        let message: String
        switch error {
        case .unauthenticated:
            message = L10n.unauthenticatedErrorDescription
        default:
            message = error.localizedDescription
        }

        showError(title: L10n.authenticationError, message: message)
    }

    private func showError(title: String, message: String?) {
        let alert = Alert(title: title, message: message, style: .alert, action: .ok)
        eventSubject.send(.alert(alert))
    }
}
