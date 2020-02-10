//
//  MetadataItem.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import LinkPresentation
import UIKit

final class MetadataItem: NSObject, UIActivityItemSource {
    private let metadata: LPLinkMetadata

    init(metadata: LPLinkMetadata) {
        self.metadata = metadata
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return false
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        return nil
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
}
