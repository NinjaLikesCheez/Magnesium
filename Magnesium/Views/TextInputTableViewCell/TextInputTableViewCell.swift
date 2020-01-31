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

    func configure(with state: TextInputTableViewCellViewState) {
        nameLabel.text = state.name
        textField.placeholder = state.placeholder
        apply(configuration: state.configuration)
        state.value
            .filter { [weak textField] in textField?.text != $0 }
            .assign(to: \.text, on: textField)
            .store(in: &observers)
        valueSubject = state.value
        state.isEnabled
            .assign(to: \.isEnabled, on: textField)
            .store(in: &observers)
    }

    private func apply(configuration: TextInputConfiguration) {
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

#if DEBUG
    struct TextInputTableViewCell_Previews: PreviewProvider {
        private struct Container: UIViewRepresentable {
            let state: TextInputTableViewCellViewState

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
                uiView.inner.configure(with: state)
            }
        }

        static var previews: some View {
            let emptyState = TextInputTableViewCellViewState(
                name: "server",
                placeholder: "https://example.com",
                value: CurrentValueSubject(nil),
                configuration: .url
            )
            let textState = TextInputTableViewCellViewState(
                name: "server",
                placeholder: "https://example.com",
                value: CurrentValueSubject("https://example.com"),
                configuration: .url
            )
            let secureState = TextInputTableViewCellViewState(
                name: "password",
                placeholder: "password",
                value: CurrentValueSubject("password"),
                configuration: .password
            )
            return ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
                Group {
                    Container(state: emptyState)
                        .previewDisplayName("Empty")
                        .previewLayout(.sizeThatFits)
                        .environment(\.colorScheme, colorScheme)
                    Container(state: textState)
                        .previewDisplayName("Text")
                        .previewLayout(.sizeThatFits)
                        .environment(\.colorScheme, colorScheme)
                    Container(state: secureState)
                        .previewDisplayName("Secure")
                        .previewLayout(.sizeThatFits)
                        .environment(\.colorScheme, colorScheme)
                }
            }
        }
    }
#endif
