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

    private lazy var nameLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        $0.font = UIFont(descriptor: descriptor, size: 0)
        $0.numberOfLines = 0
    }

    private lazy var labelLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let descriptor = base.withSymbolicTraits([.traitItalic]) ?? base
        $0.font = UIFont(descriptor: descriptor, size: 0)
        $0.numberOfLines = 0
        $0.textColor = UIColor.secondaryLabel
    }

    private lazy var topLabelsStackView = with(UIStackView(arrangedSubviews: [nameLabel, labelLabel])) {
        $0.axis = .vertical
        $0.spacing = 4
    }

    private lazy var progressView = with(UIProgressView(progressViewStyle: .bar)) {
        $0.trackTintColor = .systemGray5
    }

    private lazy var statusLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .callout)
        $0.textColor = .systemGray
    }

    private lazy var buttonStackView = with(UIStackView(arrangedSubviews: [pauseButton, removeButton])) {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.distribution = .fillEqually
    }

    private lazy var pauseButton = with(UIButton(type: .custom)) {
        $0.tintColor = .systemBlue
        $0.setPreferredSymbolConfiguration(.init(textStyle: .body), forImageIn: .normal)
        $0.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        $0.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
    }

    private lazy var removeButton = with(UIButton(type: .custom)) {
        $0.tintColor = .systemRed
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
        $0.setImage(UIImage(systemName: "trash.fill", withConfiguration: configuration), for: .normal)
        $0.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        $0.addTarget(self, action: #selector(removeButtonTapped(_:)), for: .touchUpInside)
    }

    private var isActive = true {
        didSet {
            pauseButton.setImage(UIImage(systemName: isActive ? "pause.fill" : "play.fill"), for: .normal)
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
        contentView.addSubview(topLabelsStackView)
        contentView.addSubview(progressView)
        contentView.addSubview(statusLabel)
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
