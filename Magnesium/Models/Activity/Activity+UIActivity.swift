//
//  Activity+UIActivity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-10.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

extension Activity {
    func createUIActivity() -> UIActivity {
        return _UIActivity(activity: self)
    }
}

private class _UIActivity: UIActivity {
    private let activity: Activity

    override var activityTitle: String? {
        return activity.title
    }

    override var activityImage: UIImage? {
        return activity.image
    }

    override var activityType: UIActivity.ActivityType? {
        return .init(activity.type)
    }

    override class var activityCategory: UIActivity.Category {
        return .action
    }

    init(activity: Activity) {
        self.activity = activity
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    override func perform() {
        activity.handler()
        activityDidFinish(true)
    }
}
