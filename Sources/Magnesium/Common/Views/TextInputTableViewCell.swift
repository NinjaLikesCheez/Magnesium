import Combine
import UIKit

final class TextInputTableViewCell: UITableViewCell {
    private var cancellables = Set<AnyCancellable>()
    private var valueSubject: CurrentValueSubject<String?, Never>?

    private lazy var nameLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .caption1)
    }

    private lazy var textField = with(UITextField()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .body)
        $0.addTarget(self, action: #selector(textFieldTextChanged(_:)), for: .editingChanged)
        $0.delegate = self
    }

    var proceedToNextInput: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        nameLabel.textColor = tintColor
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
        contentView.addSubview(nameLabel)
        contentView.addSubview(textField)
    }

    private func setupLayoutConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            textField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with item: TextInputItem) {
        nameLabel.text = item.name
        textField.placeholder = item.placeholder
        apply(configuration: item.configuration)
        item.value
            .filter { [weak textField] in textField?.text != $0 }
            .assign(to: \.text, on: textField)
            .store(in: &cancellables)
        valueSubject = item.value
        item.isEnabled
            .assign(to: \.isEnabled, on: textField)
            .store(in: &cancellables)
    }

    private func apply(configuration: TextInputItem.Configuration) {
        textField.isSecureTextEntry = configuration.isSecure
        textField.keyboardType = configuration.keyboardType
        textField.returnKeyType = configuration.returnKeyType
        textField.autocapitalizationType = configuration.autocapitalizationType
        textField.autocorrectionType = configuration.autocorrectionType
        textField.textContentType = configuration.textContentType
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            textField.becomeFirstResponder()
        }
    }

    @objc
    private func textFieldTextChanged(_ textField: UITextField) {
        valueSubject?.send(textField.text)
    }
}

extension TextInputTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        proceedToNextInput?()
        return false
    }
}
