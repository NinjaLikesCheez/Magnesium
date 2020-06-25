import Combine
import CommonModels
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
    private var cancellables = Set<AnyCancellable>()

    init(viewController: UIViewController, session: Session) {
        self.viewController = viewController
        self.session = session
    }

    // swiftlint:disable:next cyclomatic_complexity
    func add(type: URLType) {
        guard let server = session.server else {
            showError(title: L10n.unableToAddTorrentError, message: L10n.noServersErrorDescription)
            return
        }

        var isAccessingSecurityScopedResource = false

        if case .file = type {
            if !Current.fileSystem.isReadable(type.url) {
                _ = Current.fileSystem.startAccessingSecurityScopedResource(type.url)
                isAccessingSecurityScopedResource = true
            }
        }

        defer {
            if isAccessingSecurityScopedResource {
                Current.fileSystem.stopAccessingSecurityScopedResource(type.url)
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

            let client = Current.deluge(settings.url, keychain.password)
            let request: AnyPublisher<Void, Error>

            switch type {
            case let .file(url):
                request = client.request(.add(fileURL: url))
                    .asVoid()
                    .eraseError()
                    .eraseToAnyPublisher()
            case let .magnet(url):
                request = client.request(.add(magnetURL: url))
                    .asVoid()
                    .eraseError()
                    .eraseToAnyPublisher()
            }

            request
                .onMainThread()
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

            let client = Current.transmission(settings.url, settings.username, keychain.password)
            let request: AnyPublisher<Void, Error>

            switch type {
            case let .file(url):
                request = client.request(.add(fileURL: url)).eraseError().eraseToAnyPublisher()
            case let .magnet(url):
                request = client.request(.add(url: url)).eraseError().eraseToAnyPublisher()
            }

            request
                .onMainThread()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: L10n.failedToAddTorrentError, message: error.localizedDescription)
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }

    private func showError(title: String, message: String?) {
        var current = viewController
        while let next = current.presentedViewController {
            current = next
        }
        let alert = Alert(title: title, message: message, style: .alert, action: .ok)
        current.present(alert.createAlertController(), animated: true)
    }
}
