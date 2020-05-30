import UIKit

final class TorrentDetailSectionHeaderView: UITableViewHeaderFooterView {
    private var actionHandler: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        label.font = UIFont(descriptor: descriptor, size: 0)
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(actionButton)
    }

    private func setupLayoutConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            actionButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            actionButton.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        actionHandler = nil
    }

    @objc
    private func actionButtonTapped(_ sender: Any) {
        actionHandler?()
    }

    func configure(title: String, action: String? = nil, actionHandler: @escaping () -> Void = {}) {
        titleLabel.text = title
        actionButton.setTitle(action, for: .normal)
        actionButton.isHidden = action == nil
        self.actionHandler = actionHandler
    }
}
