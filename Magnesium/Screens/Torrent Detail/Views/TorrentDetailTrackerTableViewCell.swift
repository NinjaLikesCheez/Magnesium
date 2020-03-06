//
//  TorrentDetailTrackerTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-26.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class TorrentDetailTrackerTableViewCell: UITableViewCell {
    private lazy var trackerLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
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

    private func setup() {
        selectionStyle = .none
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        contentView.addSubview(trackerLabel)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        trackerLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            trackerLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            trackerLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            trackerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            trackerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            separatorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        ])
    }

    func configure(tracker: String, isLastRow: Bool) {
        trackerLabel.text = tracker
        separatorView.isHidden = isLastRow
    }
}
