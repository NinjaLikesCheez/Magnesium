//
//  ButtonTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import SwiftUI
import UIKit

final class ButtonTableViewCell: UITableViewCell {
    enum Style {
        case `default`
        case destructive
    }

    struct Configuration {
        var style: Style = .default
        var fontWeight: UIFont.Weight = .regular
        var alignment: NSTextAlignment = .natural
    }

    private var style: Style = .default

    private var heightConstraint: NSLayoutConstraint! {
        didSet {
            updateHeightConstraint()
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        configureStyle()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateHeightConstraint()
        }
    }

    private func setup() {
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        contentView.addSubview(titleLabel)
    }

    private func setupLayoutConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0).withPriority(.required - 1)

        NSLayoutConstraint.activate([
            heightConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateHeightConstraint() {
        heightConstraint.constant = max(44, UIFontMetrics.default.scaledValue(for: 44))
    }

    func configure(text: String, configuration: Configuration = .init()) {
        titleLabel.text = text
        style = configuration.style
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: configuration.fontWeight]])
        titleLabel.font = UIFont(descriptor: fontDescriptor, size: 0)
        titleLabel.textAlignment = configuration.alignment
        configureStyle()
    }

    private func configureStyle() {
        switch style {
        case .default:
            titleLabel.textColor = tintColor
        case .destructive:
            titleLabel.textColor = .systemRed
        }
    }
}

struct ButtonTableViewCell_Previews: PreviewProvider {
    private struct Container: UIViewRepresentable {
        let text: String
        let configuration: ButtonTableViewCell.Configuration

        func makeUIView(
            context: UIViewRepresentableContext<Container>
        ) -> PreviewViewContainer<ButtonTableViewCell> {
            return PreviewViewContainer(ButtonTableViewCell(style: .default, reuseIdentifier: nil))
        }

        func updateUIView(
            _ uiView: PreviewViewContainer<ButtonTableViewCell>,
            context: UIViewRepresentableContext<Container>
        ) {
            uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            uiView.inner.configure(text: text, configuration: configuration)
        }
    }

    static var previews: some View {
        return Group {
            Container(text: "Clear Cache", configuration: .init())
                .previewDisplayName("Light - Default")
                .previewLayout(.sizeThatFits)
            Container(text: "Delete", configuration: .init(
                style: .destructive,
                fontWeight: .semibold,
                alignment: .center
            ))
                .previewDisplayName("Light - Destructive")
                .previewLayout(.sizeThatFits)
            Container(text: "Clear Cache", configuration: .init())
                .previewDisplayName("Dark - Default")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
            Container(text: "Delete", configuration: .init(
                style: .destructive,
                fontWeight: .semibold,
                alignment: .center
            ))
                .previewDisplayName("Dark - Destructive")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}
