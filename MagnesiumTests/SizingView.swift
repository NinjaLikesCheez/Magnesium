import UIKit

final class SizingView: UIView {
    private let child: UIView
    private let width: CGFloat

    init(_ child: UIView, width: CGFloat = 375) {
        self.child = child
        self.width = width
        super.init(frame: .zero)
        addSubview(child)
        child.frame.size = UIView.layoutFittingExpandedSize
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeToFit() {
        frame.size = child.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !bounds.isEmpty {
            child.frame = bounds
        }
    }
}
