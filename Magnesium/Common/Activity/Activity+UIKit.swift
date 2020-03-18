import UIKit

extension Activity {
    func createUIActivity() -> UIActivity {
        _UIActivity(activity: self)
    }
}

private class _UIActivity: UIActivity {
    private let activity: Activity

    override var activityTitle: String? {
        activity.title
    }

    override var activityImage: UIImage? {
        activity.image
    }

    override var activityType: UIActivity.ActivityType? {
        .init(activity.type)
    }

    override class var activityCategory: UIActivity.Category {
        .action
    }

    init(activity: Activity) {
        self.activity = activity
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }

    override func perform() {
        activity.handler()
        activityDidFinish(true)
    }
}
