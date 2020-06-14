import Combine
import UIKit

protocol TorrentDetailHeaderTableViewCellDelegate: AnyObject {
    func headerDidSelectPause(_ header: TorrentDetailHeaderTableViewCell)
    func headerDidSelectResume(_ header: TorrentDetailHeaderTableViewCell)
    func headerDidSelectRemove(_ header: TorrentDetailHeaderTableViewCell, sender: UIView)
    func headerDidResize(_ header: TorrentDetailHeaderTableViewCell)
}

final class TorrentDetailHeaderTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()
    private var buttonHeightConstraint: NSLayoutConstraint?
    weak var delegate: TorrentDetailHeaderTableViewCellDelegate?

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.numberOfLines = 0
        return label
    }()

    private lazy var labelLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let descriptor = base.withSymbolicTraits([.traitItalic]) ?? base
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.numberOfLines = 0
        label.textColor = UIColor.secondaryLabel
        return label
    }()

    private lazy var topLabelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .systemGray
        return label
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .systemBlue
        button.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        button.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .systemRed
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
        button.setImage(UIImage(systemName: "trash.fill", withConfiguration: configuration), for: .normal)
        button.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        button.addTarget(self, action: #selector(removeButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    private var isActive = true {
        didSet {
            let configuration = UIImage.SymbolConfiguration(textStyle: .body)
            pauseButton.setImage(UIImage(
                systemName: isActive ? "pause.fill" : "play.fill",
                withConfiguration: configuration
            ), for: .normal)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pauseButton.layoutIfNeeded()
        pauseButton.layer.mask = {
            let mask = CAShapeLayer()
            mask.frame = pauseButton.bounds
            mask.path = UIBezierPath(roundedRect: pauseButton.bounds, cornerRadius: 8).cgPath
            return mask
        }()
        removeButton.layoutIfNeeded()
        removeButton.layer.mask = {
            let mask = CAShapeLayer()
            mask.frame = removeButton.bounds
            mask.path = UIBezierPath(roundedRect: removeButton.bounds, cornerRadius: 8).cgPath
            return mask
        }()
    }

    override func updateConstraints() {
        super.updateConstraints()
        buttonHeightConstraint?.constant = UIFontMetrics.default.scaledValue(for: 40)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setNeedsUpdateConstraints()
        }

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            pauseButton.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
            removeButton.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }

    private func setup() {
        selectionStyle = .none
        UIView.performWithoutAnimation {
            setupViews()
            setupLayoutConstraints()
        }
    }

    private func setupViews() {
        topLabelsStackView.addArrangedSubview(nameLabel)
        topLabelsStackView.addArrangedSubview(labelLabel)
        contentView.addSubview(topLabelsStackView)
        contentView.addSubview(progressView)
        contentView.addSubview(statusLabel)
        buttonStackView.addArrangedSubview(pauseButton)
        buttonStackView.addArrangedSubview(removeButton)
        contentView.addSubview(buttonStackView)
    }

    private func setupLayoutConstraints() {
        for view in [topLabelsStackView, progressView, statusLabel, buttonStackView] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        nameLabel.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
        labelLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .vertical)
        statusLabel.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)

        buttonHeightConstraint = buttonStackView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            topLabelsStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            topLabelsStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            topLabelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            progressView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: topLabelsStackView.bottomAnchor, constant: 8)
                .withPriority(.defaultHigh),

            statusLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),

            buttonStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            buttonStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            buttonHeightConstraint!,
        ])
    }

    func configure(with item: TorrentDetailHeaderItem) {
        item.name
            .asOptional()
            .assign(to: \.text, on: nameLabel)
            .store(in: &cancellables)

        item.label
            .filter { !$0.isEmpty }
            .asOptional()
            .assign(to: \.text, on: labelLabel)
            .store(in: &cancellables)

        item.label
            .map(\.isEmpty)
            .assign(to: \.isHidden, on: labelLabel)
            .store(in: &cancellables)

        item.label
            .map(\.isEmpty)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.headerDidResize(strongSelf)
            }
            .store(in: &cancellables)

        item.isActive
            .sink { [weak self] in self?.isActive = $0 }
            .store(in: &cancellables)

        item.progress
            .assign(to: \.progress, on: progressView)
            .store(in: &cancellables)

        item.progressColor
            .asOptional()
            .assign(to: \.progressTintColor, on: progressView)
            .store(in: &cancellables)

        item.status
            .asOptional()
            .assign(to: \.text, on: statusLabel)
            .store(in: &cancellables)
    }

    @objc
    private func pauseButtonTapped() {
        if isActive {
            delegate?.headerDidSelectPause(self)
        } else {
            delegate?.headerDidSelectResume(self)
        }
    }

    @objc
    private func removeButtonTapped(_ sender: UIButton) {
        delegate?.headerDidSelectRemove(self, sender: sender)
    }
}
