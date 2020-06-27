import Combine
import UIKit

final class TorrentDetailFileTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()

    private lazy var topStackView = with(UIStackView(arrangedSubviews: [nameLabel, priorityImageViewContainer])) {
        $0.axis = .horizontal
        $0.spacing = 8
    }

    private lazy var nameLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.numberOfLines = 0
    }

    private lazy var priorityImageViewContainer = UIView()

    private lazy var priorityImageView = with(UIImageView()) {
        $0.preferredSymbolConfiguration = .init(textStyle: .subheadline)
    }

    private lazy var infoLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
    }

    private lazy var separatorView = with(UIView()) {
        $0.backgroundColor = .separator
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
        priorityImageViewContainer.addSubview(priorityImageView)

        contentView.addSubview(topStackView)
        contentView.addSubview(infoLabel)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        // priorityImageViewContainer

        priorityImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            priorityImageView.leadingAnchor.constraint(equalTo: priorityImageViewContainer.leadingAnchor),
            priorityImageView.trailingAnchor.constraint(equalTo: priorityImageViewContainer.trailingAnchor),
            priorityImageView.topAnchor.constraint(equalTo: priorityImageViewContainer.topAnchor),
            priorityImageView.bottomAnchor.constraint(lessThanOrEqualTo: priorityImageViewContainer.bottomAnchor),
        ])

        // main content

        topStackView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        priorityImageView.setContentHuggingPriority(.required, for: .horizontal)
        priorityImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        infoLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)

        NSLayoutConstraint.activate([
            topStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            topStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            topStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            infoLabel.leadingAnchor.constraint(equalTo: topStackView.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: topStackView.trailingAnchor),
            infoLabel.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 2),
            infoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            separatorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        ])
    }

    func configure(with item: TorrentDetailFileItem, isLastRow: Bool) {
        item.name
            .asOptional()
            .assign(to: \.text, on: nameLabel)
            .store(in: &cancellables)

        item.info
            .asOptional()
            .assign(to: \.text, on: infoLabel)
            .store(in: &cancellables)

        item.priorityImage
            .assign(to: \.image, on: priorityImageView)
            .store(in: &cancellables)

        item.priorityImage
            .map { $0 == nil }
            .assign(to: \.isHidden, on: priorityImageViewContainer)
            .store(in: &cancellables)

        separatorView.isHidden = isLastRow
    }
}
