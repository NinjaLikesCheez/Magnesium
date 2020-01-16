//
//  TextInputTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class TextInputTableViewCell: UITableViewCell {
    private var observers = [AnyCancellable]()
    private var valueSubject: CurrentValueSubject<String?, Never>?

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        return label
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.adjustsFontForContentSizeCategory = true
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.addTarget(self, action: #selector(textFieldTextChanged(_:)), for: .editingChanged)
        textField.delegate = self
        return textField
    }()

    var proceedToNextInput: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        nameLabel.textColor = tintColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        observers = []
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

    func configure(with viewModel: TextInputTableViewCellViewModel) {
        nameLabel.text = viewModel.name
        textField.placeholder = viewModel.placeholder
        textField.isSecureTextEntry = viewModel.isSecure
        textField.keyboardType = viewModel.keyboardType
        textField.returnKeyType = viewModel.returnKeyType
        textField.textContentType = viewModel.textContentType
        textField.autocapitalizationType = viewModel.autocapitalizationType
        viewModel.value
            .filter { [weak textField] in textField?.text != $0 }
            .assign(to: \.text, on: textField)
            .store(in: &observers)
        valueSubject = viewModel.value
        viewModel.isEnabled
            .assign(to: \.isEnabled, on: textField)
            .store(in: &observers)
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

#if DEBUG
    struct TextInputTableViewCell_Previews: PreviewProvider {
        private struct Container: UIViewRepresentable {
            let viewModel: TextInputTableViewCellViewModel

            init(viewModel: TextInputTableViewCellViewModel) {
                self.viewModel = viewModel
            }

            func makeUIView(
                context: UIViewRepresentableContext<Container>
            ) -> PreviewViewContainer<TextInputTableViewCell> {
                return PreviewViewContainer(TextInputTableViewCell(style: .default, reuseIdentifier: nil))
            }

            func updateUIView(
                _ uiView: PreviewViewContainer<TextInputTableViewCell>,
                context: UIViewRepresentableContext<Container>
            ) {
                uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
                uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                uiView.inner.configure(with: viewModel)
            }
        }

        static var previews: some View {
            let emptyViewModel = DefaultTextInputTableViewCellViewModel(
                name: "server",
                placeholder: "https://example.com",
                value: CurrentValueSubject(nil),
                isSecure: false
            )
            let textViewModel = DefaultTextInputTableViewCellViewModel(
                name: "server",
                placeholder: "https://example.com",
                value: CurrentValueSubject("https://example.com"),
                isSecure: false
            )
            let secureViewModel = DefaultTextInputTableViewCellViewModel(
                name: "password",
                placeholder: "password",
                value: CurrentValueSubject("password"),
                isSecure: true
            )
            return Group {
                Container(viewModel: emptyViewModel)
                    .previewDisplayName("Light - No Text")
                    .previewLayout(.sizeThatFits)
                Container(viewModel: textViewModel)
                    .previewDisplayName("Light - Text")
                    .previewLayout(.sizeThatFits)
                Container(viewModel: secureViewModel)
                    .previewDisplayName("Light - Secure")
                    .previewLayout(.sizeThatFits)
                Container(viewModel: emptyViewModel)
                    .previewDisplayName("Dark - No Text")
                    .previewLayout(.sizeThatFits)
                    .environment(\.colorScheme, .dark)
                Container(viewModel: textViewModel)
                    .previewDisplayName("Dark - Text")
                    .previewLayout(.sizeThatFits)
                    .environment(\.colorScheme, .dark)
                Container(viewModel: secureViewModel)
                    .previewDisplayName("Dark - Secure")
                    .previewLayout(.sizeThatFits)
                    .environment(\.colorScheme, .dark)
            }
        }
    }
#endif
