import Combine
import UIKit

final class TorrentDetailFileTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var progressLabel: UILabel = {
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
        contentView.addSubview(nameLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(sizeLabel)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        progressLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        progressLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        sizeLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -8),

            progressLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: sizeLabel.bottomAnchor),

            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            sizeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

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

        item.size
            .asOptional()
            .assign(to: \.text, on: sizeLabel)
            .store(in: &cancellables)

        item.progress
            .asOptional()
            .assign(to: \.text, on: progressLabel)
            .store(in: &cancellables)

        separatorView.isHidden = isLastRow
    }
}
