import Combine
import UIKit

struct TorrentListItem: Equatable, Hashable {
    let hash: String
    var name: UIPublisher<String>
    var label: UIPublisher<String>
    var progress: UIPublisher<Float>
    var progressColor: UIPublisher<UIColor>
    var status: UIPublisher<String>
    var speed: UIPublisher<String>
    var progressText: UIPublisher<String>
    var ratioOrETA: UIPublisher<String>
}

extension TorrentListItem {
    init(torrentSubject: CurrentValueSubject<StandardTorrent, Never>) {
        hash = torrentSubject.value.hash
        name = torrentSubject.map(\.name).ui()
        label = torrentSubject.map(\.label).ui()
        progress = torrentSubject.map(\.progress).ui()
        progressColor = torrentSubject.map(\.state.displayColor).ui()
        status = torrentSubject.map(\.state.localizedString).ui()
        speed = torrentSubject.map(\.localizedSpeed).ui()
        progressText = torrentSubject.map(\.localizedProgress).ui()
        ratioOrETA = torrentSubject.map(\.localizedRatioOrETA).ui()
    }
}
