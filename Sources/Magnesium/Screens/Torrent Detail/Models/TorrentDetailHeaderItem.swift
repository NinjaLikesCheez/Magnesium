import Combine
import UIKit

struct TorrentDetailHeaderItem: Equatable, Hashable {
    let id: String
    var name: UIPublisher<String>
    var isActive: UIPublisher<Bool>
    var progress: UIPublisher<Float>
    var progressColor: UIPublisher<UIColor>
    var status: UIPublisher<String>
    var label: UIPublisher<String>

    init(torrentSubject: CurrentValueSubject<StandardTorrent, Never>) {
        id = torrentSubject.value.hash
        name = torrentSubject.map(\.name).ui()
        isActive = torrentSubject.map(\.isActive).ui()
        progress = torrentSubject.map(\.progress).ui()
        progressColor = torrentSubject.map(\.state.displayColor).ui()
        status = torrentSubject
            .map {
                L10n.Torrent.torrentStatusWithPercentage(
                    status: $0.state.localizedString,
                    progress: Formatters.percentage(precision: 2).string(for: $0.progress) ?? ""
                )
            }
            .ui()
        label = torrentSubject.map(\.label).ui()
    }
}
