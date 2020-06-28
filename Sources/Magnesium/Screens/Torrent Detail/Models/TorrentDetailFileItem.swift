import Combine
import UIKit

struct TorrentDetailFileItem: Identifiable {
    let id: Int
    var name: AnyPublisher<String, Never>
    var info: AnyPublisher<String, Never>
    var priorityImage: AnyPublisher<UIImage?, Never>

    init(fileSubject: CurrentValueSubject<StandardTorrentFile, Never>) {
        id = fileSubject.value.index
        name = fileSubject.map(\.name).ui().eraseToAnyPublisher()
        info = fileSubject.map(\.localizedProgress).ui().eraseToAnyPublisher()
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
        }.ui().eraseToAnyPublisher()
    }
}
