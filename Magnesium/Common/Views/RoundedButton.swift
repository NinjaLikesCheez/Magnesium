import UIKit

final class RoundedButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }

    var cornerRadius: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }

    init() {
        super.init(frame: .zero)
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        backgroundColor = .systemBlue
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        titleLabel?.font = UIFont(descriptor: descriptor, size: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.mask = {
            let mask = CAShapeLayer()
            mask.frame = bounds
            mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
            return mask
        }()
    }
}
