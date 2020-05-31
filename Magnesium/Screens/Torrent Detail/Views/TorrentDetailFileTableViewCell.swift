import Combine
import UIKit

final class TorrentDetailFileTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()

    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, priorityImageViewContainer])
        stackView.axis = .horizontal
        stackView.spacing = 8
        return stackView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()

    private lazy var priorityImageViewContainer = UIView()

    private lazy var priorityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = .init(textStyle: .subheadline)
        return imageView
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

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

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        selectedBackgroundView = editing ? UIImageView(image: UIImage(color: .systemGray5)) : nil
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
