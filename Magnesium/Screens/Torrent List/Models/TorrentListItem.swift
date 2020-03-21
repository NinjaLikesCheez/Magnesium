import Combine
import UIKit

struct TorrentListItem: Identifiable {
    let id: String
    var name: AnyPublisher<String, Never>
    var progress: AnyPublisher<Float, Never>
    var progressColor: AnyPublisher<UIColor, Never>
    var state: AnyPublisher<String, Never>
    var speed: AnyPublisher<String, Never>
    var progressString: AnyPublisher<String, Never>
    var ratioOrETA: AnyPublisher<String, Never>

    init<Torrent: StandardTorrent>(torrent: CurrentValueSubject<Torrent, Never>) {
        id = torrent.value.hash
        name = torrent.map(\.name).ui().eraseToAnyPublisher()
        progress = torrent.map(\.progress).ui().eraseToAnyPublisher()
        progressColor = torrent.map(\.standardState.displayColor).ui().eraseToAnyPublisher()
        state = torrent.map(\.standardState.localizedString).ui().eraseToAnyPublisher()
        speed = torrent.map(\.localizedSpeed).ui().eraseToAnyPublisher()
        progressString = torrent.map(\.localizedProgress).ui().eraseToAnyPublisher()
        ratioOrETA = torrent.map(\.localizedRatioOrETA).ui().eraseToAnyPublisher()
    }
}

extension TorrentListItem: Equatable {
    static func == (lhs: TorrentListItem, rhs: TorrentListItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension TorrentListItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
