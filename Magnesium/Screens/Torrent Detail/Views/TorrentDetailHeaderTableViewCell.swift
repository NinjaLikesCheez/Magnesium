//
//  TorrentDetailHeaderTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class TorrentDetailHeaderTableViewCell: UITableViewCell {
    private var observers = [AnyCancellable]()
    private var buttonHeightConstraint: NSLayoutConstraint?

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.numberOfLines = 0
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .systemBlue
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
        button.setImage(UIImage(systemName: "pause.fill", withConfiguration: configuration), for: .normal)
        button.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .systemRed
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
        button.setImage(UIImage(systemName: "trash.fill", withConfiguration: configuration), for: .normal)
        button.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pauseButton.layoutIfNeeded()
        pauseButton.layer.mask = {
            let mask = CAShapeLayer()
            mask.frame = pauseButton.bounds
            mask.path = UIBezierPath(roundedRect: pauseButton.bounds, cornerRadius: 8).cgPath
            return mask
        }()
        removeButton.layoutIfNeeded()
        removeButton.layer.mask = {
            let mask = CAShapeLayer()
            mask.frame = removeButton.bounds
            mask.path = UIBezierPath(roundedRect: removeButton.bounds, cornerRadius: 8).cgPath
            return mask
        }()
    }

    override func updateConstraints() {
        super.updateConstraints()
        buttonHeightConstraint?.constant = UIFontMetrics.default.scaledValue(for: 40)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setNeedsUpdateConstraints()
        }

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            pauseButton.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
            removeButton.setBackgroundImage(UIImage(color: .tertiarySystemFill), for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        observers = []
    }

    private func setup() {
        UIView.performWithoutAnimation {
            setupViews()
            setupLayoutConstraints()
        }
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(statusLabel)
        buttonStackView.addArrangedSubview(pauseButton)
        buttonStackView.addArrangedSubview(removeButton)
        contentView.addSubview(buttonStackView)
    }

    private func setupLayoutConstraints() {
        for view in [nameLabel, progressView, statusLabel, buttonStackView] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        statusLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        buttonHeightConstraint = buttonStackView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            progressView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            statusLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),

            buttonStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            buttonStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            buttonHeightConstraint!,
        ])
    }

    func configure<VM: TorrentDetailHeaderViewModel>(with viewModel: VM) {
        // swiftlint:disable array_init
        viewModel.name
            .map { text -> String? in text }
            .assign(to: \.text, on: nameLabel)
            .store(in: &observers)

        viewModel.progress
            .assign(to: \.progress, on: progressView)
            .store(in: &observers)

        viewModel.progressColor
            .map { color -> UIColor? in color }
            .assign(to: \.progressTintColor, on: progressView)
            .store(in: &observers)

        viewModel.status
            .map { text -> String? in text }
            .assign(to: \.text, on: statusLabel)
            .store(in: &observers)
        // swiftlint:enable array_init
    }
}

#if DEBUG
    struct TorrentDetailHeaderTableViewCell_Previews: PreviewProvider {
        private struct Container<VM: TorrentDetailHeaderViewModel>: UIViewRepresentable {
            let viewModel: VM

            init(viewModel: VM) {
                self.viewModel = viewModel
            }

            func makeUIView(
                context: UIViewRepresentableContext<Container<VM>>
            ) -> PreviewViewContainer<TorrentDetailHeaderTableViewCell> {
                return PreviewViewContainer(TorrentDetailHeaderTableViewCell(style: .default, reuseIdentifier: nil))
            }

            func updateUIView(
                _ uiView: PreviewViewContainer<TorrentDetailHeaderTableViewCell>,
                context: UIViewRepresentableContext<Container<VM>>
            ) {
                uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
                uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                uiView.inner.configure(with: viewModel)
            }
        }

        static var previews: some View {
            let viewModel = MockTorrentDetailHeaderViewModel(torrentSubject: CurrentValueSubject(MockTorrent(
                id: 0,
                name: "Torrent",
                state: .seeding,
                size: 1024,
                downloaded: 1024,
                uploaded: 4098,
                downloadRate: 0,
                uploadRate: 0,
                eta: 0,
                seeds: 0,
                totalSeeds: 0,
                peers: 0,
                totalPeers: 0,
                trackers: []
            )))
            return Group {
                Container(viewModel: viewModel)
                    .previewDisplayName("Light")
                    .previewLayout(.sizeThatFits)
                Container(viewModel: viewModel)
                    .previewLayout(.sizeThatFits)
                    .previewDisplayName("Dark")
                    .environment(\.colorScheme, .dark)
            }
        }
    }
#endif
