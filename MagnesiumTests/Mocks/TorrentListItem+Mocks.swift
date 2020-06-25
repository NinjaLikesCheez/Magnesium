@testable import Magnesium
import UIKit

extension TorrentListItem {
    static func mock(
        hash: String = "",
        name: String = "",
        label: String = "",
        progress: Float = 0,
        progressColor: UIColor = TorrentState.downloading.displayColor,
        status: String = "",
        speed: String = "",
        progressText: String = "",
        ratioOrETA: String = ""
    ) -> Self {
        .init(
            hash: hash,
            name: .init(name),
            label: .init(label),
            progress: .init(progress),
            progressColor: .init(progressColor),
            status: .init(status),
            speed: .init(speed),
            progressText: .init(progressText),
            ratioOrETA: .init(ratioOrETA)
        )
    }
}
