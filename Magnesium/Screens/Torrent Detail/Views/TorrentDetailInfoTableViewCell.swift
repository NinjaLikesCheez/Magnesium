import Combine
import UIKit

final class TorrentDetailInfoTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        return stackView
    }()

    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        return stackView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }()

    private lazy var expandedValueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()

    private lazy var expandImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = UIImage(systemName: "chevron.down")
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline)
        return imageView
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
        selectionStyle = .none
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        horizontalStackView.addArrangedSubview(nameLabel)
        horizontalStackView.addArrangedSubview(valueLabel)
        horizontalStackView.addArrangedSubview(expandImageView)
        verticalStackView.addArrangedSubview(horizontalStackView)
        verticalStackView.addArrangedSubview(expandedValueLabel)
        contentView.addSubview(verticalStackView)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            separatorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        ])
    }

    func configure(with item: TorrentDetailInfoItem, isExpanded: Bool, isLastRow: Bool) {
        nameLabel.text = item.name
        separatorView.isHidden = isLastRow

        if isExpanded, let expandedValue = item.expandedValue {
            configureForExpanded()
            expandedValue
                .asOptional()
                .assign(to: \.text, on: expandedValueLabel)
                .store(in: &cancellables)
        } else {
            configureForCollapsed()
            expandImageView.isHidden = item.expandedValue == nil
            item.value
                .asOptional()
                .assign(to: \.text, on: valueLabel)
                .store(in: &cancellables)
        }
    }

    private func configureForExpanded() {
        valueLabel.alpha = 0
        expandImageView.alpha = 0
        expandedValueLabel.alpha = 1
        expandedValueLabel.isHidden = false
    }

    private func configureForCollapsed() {
        valueLabel.alpha = 1
        expandImageView.alpha = 1
        expandedValueLabel.alpha = 0
        expandedValueLabel.isHidden = true
    }

    func prepareForExpansion() {
        valueLabel.alpha = 1
        expandImageView.alpha = 1
        expandedValueLabel.alpha = 0
    }

    func animateExpansion() {
        UIView.animate(withDuration: 0.25) {
            self.valueLabel.alpha = 0
            self.expandImageView.alpha = 0
            self.expandedValueLabel.alpha = 1
        }
    }
}
