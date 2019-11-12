//
//  TorrentDetailSectionHeaderView.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-26.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class TorrentDetailSectionHeaderView: UIView {
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        label.font = UIFont(descriptor: descriptor, size: 0)
        return label
    }()

    private var titleTopConstraint: NSLayoutConstraint?
    private var titleBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()
        let titleSpacing = UIFontMetrics.default.scaledValue(for: 11)
        titleTopConstraint?.constant = titleSpacing
        titleBottomConstraint?.constant = -titleSpacing
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setNeedsUpdateConstraints()
        }
    }

    private func setup() {
        preservesSuperviewLayoutMargins = true
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        addSubview(separatorView)
        addSubview(titleLabel)
    }

    private func setupLayoutConstraints() {
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),

            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            titleTopConstraint!,
            titleBottomConstraint!,
        ])
    }

    func configure(withTitle title: String) {
        titleLabel.text = title
    }
}
