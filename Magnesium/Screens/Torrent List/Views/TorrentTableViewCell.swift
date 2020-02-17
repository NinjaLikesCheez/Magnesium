//
//  TorrentTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

final class TorrentTableViewCell: UITableViewCell {
    private var observers = [AnyCancellable]()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.numberOfLines = 2
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var ratioOrETALabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    static var estimatedHeight: CGFloat {
        return 8
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        observers = []
    }

    private func setup() {
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(stateLabel)
        contentView.addSubview(speedLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(ratioOrETALabel)
    }

    private func setupLayoutConstraints() {
        for view in [nameLabel, progressView, stateLabel, speedLabel, progressLabel, ratioOrETALabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        stateLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        progressLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            progressView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            stateLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stateLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),

            speedLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stateLabel.trailingAnchor, constant: 8),
            speedLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            speedLabel.topAnchor.constraint(equalTo: stateLabel.topAnchor),
            speedLabel.bottomAnchor.constraint(equalTo: stateLabel.bottomAnchor),

            progressLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 2),
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
            .store(in: &observers)

        item.progress
            .assign(to: \.progress, on: progressView)
            .store(in: &observers)

        item.progressColor
            .asOptional()
            .assign(to: \.progressTintColor, on: progressView)
            .store(in: &observers)

        item.state
            .asOptional()
            .assign(to: \.text, on: stateLabel)
            .store(in: &observers)

        item.speed
            .asOptional()
            .assign(to: \.text, on: speedLabel)
            .store(in: &observers)

        item.progressString
            .asOptional()
            .assign(to: \.text, on: progressLabel)
            .store(in: &observers)

        item.ratioOrETA
            .asOptional()
            .assign(to: \.text, on: ratioOrETALabel)
            .store(in: &observers)
    }
}
