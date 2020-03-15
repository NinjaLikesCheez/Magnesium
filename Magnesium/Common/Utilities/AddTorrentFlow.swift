import Combine
import Deluge
import Transmission
import UIKit

final class AddTorrentFlow {
    enum URLType {
        case file(URL)
        case magnet(URL)

        var url: URL {
            switch self {
            case let .file(url), let .magnet(url):
                return url
            }
        }
    }

    private let viewController: UIViewController
    private let session: Session
    private let delugeClientProvider: DelugeClientProvider
    private let transmissionClientProvider: TransmissionClientProvider
    private var cancellables = Set<AnyCancellable>()

    init(
        viewController: UIViewController,
        session: Session,
        delugeClientProvider: DelugeClientProvider = DefaultDelugeClientProvider(),
        transmissionClientProvider: TransmissionClientProvider = DefaultTransmissionClientProvider()
    ) {
        self.viewController = viewController
        self.session = session
        self.delugeClientProvider = delugeClientProvider
        self.transmissionClientProvider = transmissionClientProvider
    }

    // swiftlint:disable:next cyclomatic_complexity
    func add(type: URLType) {
        guard let server = session.server else {
            showError(title: L10n.unableToAddTorrentError, message: L10n.noServersErrorDescription)
            return
        }

        var isAccessingSecurityScopedResource = false

        if case .file = type {
            if !FileManager.default.isReadableFile(atPath: type.url.absoluteString) {
                _ = type.url.startAccessingSecurityScopedResource()
                isAccessingSecurityScopedResource = true
            }
        }

        defer {
            if isAccessingSecurityScopedResource {
                type.url.stopAccessingSecurityScopedResource()
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
                showError(title: L10n.unableToAddTorrentError, message: L10n.corruptServerSettingsErrorDescription)
                return
            }

            let client = delugeClientProvider.createClient(baseURL: settings.url, password: keychain.password)
            let request: AnyPublisher<Void, DelugeError>

            switch type {
            case let .file(url):
                request = client.request(.add(fileURL: url)).map { _ in () }.eraseToAnyPublisher()
            case let .magnet(url):
                request = client.request(.add(magnetURL: url)).map { _ in () }.eraseToAnyPublisher()
            }

            request
                .ui()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: L10n.failedToAddTorrentError, message: error.localizedDescription)
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: server.data),
                let keychain = server.keychainData.flatMap({
                    try? decoder.decode(TransmissionKeychainData.self, from: $0)
                })
            else {
                showError(title: L10n.unableToAddTorrentError, message: L10n.corruptServerSettingsErrorDescription)
                return
            }

            let client = transmissionClientProvider.createClient(
                baseURL: settings.url,
                username: settings.username,
                password: keychain.password
            )
            let request: AnyPublisher<Void, TransmissionError>

            switch type {
            case let .file(url):
                request = client.request(.add(fileURL: url))
            case let .magnet(url):
                request = client.request(.add(url: url))
            }

            request
                .ui()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: L10n.failedToAddTorrentError, message: error.localizedDescription)
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(title: title, message: message, style: .alert)
        alert.addAction(.ok)
        var current = viewController
        while let next = current.presentedViewController {
            current = next
        }
        current.present(alert.createAlertController(), animated: true)
    }
}
