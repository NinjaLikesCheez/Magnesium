import Combine
import UIKit

struct TorrentDetailFileItem: Equatable, Hashable {
    let id: Int
    var name: UIPublisher<String>
    var info: UIPublisher<String>
    var priorityImage: UIPublisher<UIImage?>

    init(fileSubject: CurrentValueSubject<StandardTorrentFile, Never>) {
        id = fileSubject.value.index
        name = fileSubject.map(\.name).ui()
        info = fileSubject.map(\.localizedProgress).ui()
        priorityImage = fileSubject.map { file -> UIImage? in
            switch file.priority {
            case .disabled:
                return UIImage(systemName: "slash.circle")?
                    .withTintColor(.systemRed)
                    .withRenderingMode(.alwaysOriginal)
            case .low:
                return UIImage(systemName: "arrow.down.circle")?
                    .withTintColor(.systemOrange)
                    .withRenderingMode(.alwaysOriginal)
            case .normal:
                return nil
            case .high:
                return UIImage(systemName: "arrow.up.circle")?
                    .withTintColor(.systemGreen)
                    .withRenderingMode(.alwaysOriginal)
            }
        }.ui()
    }
}
