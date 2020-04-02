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

    init(torrent: CurrentValueSubject<StandardTorrent, Never>) {
        id = torrent.value.hash
        name = torrent.map(\.name).ui().eraseToAnyPublisher()
        isActive = torrent.map(\.isActive).ui().eraseToAnyPublisher()
        progress = torrent.map(\.progress).ui().eraseToAnyPublisher()
        progressColor = torrent.map(\.state.displayColor).ui().eraseToAnyPublisher()
        status = torrent
            .map {
                L10n.torrentStatusAndProgress(
                    status: $0.state.localizedString,
                    progress: Formatters.percentage(precision: 2).string(for: $0.progress) ?? ""
                )
            }
            .ui()
            .eraseToAnyPublisher()
        label = torrent.map(\.label).ui().eraseToAnyPublisher()
    }
}
