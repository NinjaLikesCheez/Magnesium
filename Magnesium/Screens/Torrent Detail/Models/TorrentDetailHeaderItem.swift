import Combine
import UIKit

struct TorrentDetailHeaderItem: Identifiable {
    let id: String
    var name: AnyPublisher<String, Never>
    var isActive: AnyPublisher<Bool, Never>
    var progress: AnyPublisher<Float, Never>
    var progressColor: AnyPublisher<UIColor, Never>
    var status: AnyPublisher<String, Never>
    var label: AnyPublisher<String, Never>

    init(torrentSubject: CurrentValueSubject<StandardTorrent, Never>) {
        id = torrentSubject.value.hash
        name = torrentSubject.map(\.name).ui().eraseToAnyPublisher()
        isActive = torrentSubject.map(\.isActive).ui().eraseToAnyPublisher()
        progress = torrentSubject.map(\.progress).ui().eraseToAnyPublisher()
        progressColor = torrentSubject.map(\.state.displayColor).ui().eraseToAnyPublisher()
        status = torrentSubject
            .map {
                L10n.torrentStatusAndProgress(
                    status: $0.state.localizedString,
                    progress: Formatters.percentage(precision: 2).string(for: $0.progress) ?? ""
                )
            }
            .ui()
            .eraseToAnyPublisher()
        label = torrentSubject.map(\.label).ui().eraseToAnyPublisher()
    }
}
