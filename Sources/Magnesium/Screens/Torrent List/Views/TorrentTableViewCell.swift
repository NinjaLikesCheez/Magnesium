import Combine
import UIKit

final class TorrentTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()
    private var labelLabelTopConstraint: NSLayoutConstraint?

    private lazy var nameLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .callout)
        $0.numberOfLines = 2
    }

    private lazy var labelLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        let descriptor = base.withSymbolicTraits([.traitItalic]) ?? base
        $0.font = UIFont(descriptor: descriptor, size: 0)
        $0.textColor = .systemGray
    }

    private lazy var progressView = with(UIProgressView(progressViewStyle: .bar)) {
        $0.trackTintColor = .systemGray5
    }

    private lazy var statusLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .systemGray
    }

    private lazy var speedLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .systemGray
    }

    private lazy var progressLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .systemGray
    }

    private lazy var ratioOrETALabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .systemGray
    }

    static var estimatedHeight: CGFloat {
        8
            + UIFont.preferredFont(forTextStyle: .callout).lineHeight
            + 8
            + 2.5
            + 8
            + UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
            + 2
            + UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
            + 8
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }

    private func setup() {
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(labelLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(statusLabel)
        contentView.addSubview(speedLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(ratioOrETALabel)
    }

    private func setupLayoutConstraints() {
        for view in [nameLabel, labelLabel, progressView, statusLabel, speedLabel, progressLabel, ratioOrETALabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        speedLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        ratioOrETALabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        labelLabelTopConstraint = labelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            labelLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            labelLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            labelLabelTopConstraint!,

            progressView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 8),

            statusLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),

            speedLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 8),
            speedLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            speedLabel.topAnchor.constraint(equalTo: statusLabel.topAnchor),
            speedLabel.bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor),

            progressLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 2),
            progressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            ratioOrETALabel.leadingAnchor.constraint(greaterThanOrEqualTo: progressLabel.trailingAnchor, constant: 8),
            ratioOrETALabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            ratioOrETALabel.topAnchor.constraint(equalTo: progressLabel.topAnchor),
            ratioOrETALabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(with item: TorrentListItem) {
        item.name
            .asOptional()
            .assign(to: \.text, on: nameLabel)
            .store(in: &cancellables)

        item.label
            .asOptional()
            .assign(to: \.text, on: labelLabel)
            .store(in: &cancellables)

        item.label
            .map(\.isEmpty)
            .sink { [weak self] isEmpty in
                self?.labelLabelTopConstraint?.constant = isEmpty ? 0 : 2
            }
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

        item.speed
            .asOptional()
            .assign(to: \.text, on: speedLabel)
            .store(in: &cancellables)

        item.progressText
            .asOptional()
            .assign(to: \.text, on: progressLabel)
            .store(in: &cancellables)

        item.ratioOrETA
            .asOptional()
            .assign(to: \.text, on: ratioOrETALabel)
            .store(in: &cancellables)
    }
}
