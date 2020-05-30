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

    init(torrentSubject: CurrentValueSubject<StandardTorrent, Never>) {
        id = torrentSubject.value.hash
        name = torrentSubject.map(\.name).ui().eraseToAnyPublisher()
        progress = torrentSubject.map(\.progress).ui().eraseToAnyPublisher()
        progressColor = torrentSubject.map(\.state.displayColor).ui().eraseToAnyPublisher()
        state = torrentSubject.map(\.state.localizedString).ui().eraseToAnyPublisher()
        speed = torrentSubject.map(\.localizedSpeed).ui().eraseToAnyPublisher()
        progressString = torrentSubject.map(\.localizedProgress).ui().eraseToAnyPublisher()
        ratioOrETA = torrentSubject.map(\.localizedRatioOrETA).ui().eraseToAnyPublisher()
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
