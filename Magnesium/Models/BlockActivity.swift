//
//  BlockActivity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

class BlockActivity: UIActivity {
    private let title: String?
    private let image: UIImage?
    private let type: UIActivity.ActivityType?
    private let handler: () -> Void

    override var activityTitle: String? {
        return title
    }

    override var activityImage: UIImage? {
        return image
    }

    override var activityType: UIActivity.ActivityType? {
        return type
    }

    override class var activityCategory: UIActivity.Category {
        return .action
    }

    init(title: String?, image: UIImage?, type: UIActivity.ActivityType?, handler: @escaping () -> Void) {
        self.title = title
        self.image = image
        self.type = type
        self.handler = handler
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    override func perform() {
        handler()
        activityDidFinish(true)
    }
}
