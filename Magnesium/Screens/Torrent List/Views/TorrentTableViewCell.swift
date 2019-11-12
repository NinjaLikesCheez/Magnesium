//
//  TorrentTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class TorrentTableViewCell: UITableViewCell {
    private var observers = [AnyCancellable]()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 2
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var detail1Label: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var detail2Label: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var detail3Label: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

    private lazy var detail4Label: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray
        return label
    }()

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
        contentView.addSubview(detail1Label)
        contentView.addSubview(detail2Label)
        contentView.addSubview(detail3Label)
        contentView.addSubview(detail4Label)
    }

    private func setupLayoutConstraints() {
        for view in [nameLabel, progressView, detail1Label, detail2Label, detail3Label, detail4Label] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        detail1Label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        detail3Label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),

            progressView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressView.topAnchor.constraint(equalToSystemSpacingBelow: nameLabel.bottomAnchor, multiplier: 1),

            detail1Label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            detail1Label.topAnchor.constraint(equalToSystemSpacingBelow: progressView.bottomAnchor, multiplier: 1),

            detail2Label.leadingAnchor.constraint(greaterThanOrEqualTo: detail1Label.trailingAnchor, constant: 8),
            detail2Label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            detail2Label.topAnchor.constraint(equalTo: detail1Label.topAnchor),
            detail2Label.bottomAnchor.constraint(equalTo: detail1Label.bottomAnchor),

            detail3Label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            detail3Label.topAnchor.constraint(equalTo: detail1Label.bottomAnchor, constant: 2),
            detail3Label.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),

            detail4Label.leadingAnchor.constraint(greaterThanOrEqualTo: detail3Label.trailingAnchor, constant: 8),
            detail4Label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            detail4Label.topAnchor.constraint(equalTo: detail3Label.topAnchor),
            detail4Label.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    func configure<VM: TorrentListItemViewModel>(with viewModel: VM) {
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

        viewModel.detail1
            .map { text -> String? in text }
            .assign(to: \.text, on: detail1Label)
            .store(in: &observers)

        viewModel.detail2
            .map { text -> String? in text }
            .assign(to: \.text, on: detail2Label)
            .store(in: &observers)

        viewModel.detail3
            .map { text -> String? in text }
            .assign(to: \.text, on: detail3Label)
            .store(in: &observers)

        viewModel.detail4
            .map { text -> String? in text }
            .assign(to: \.text, on: detail4Label)
            .store(in: &observers)
        // swiftlint:enable array_init
    }
}

#if DEBUG
    struct TorrentTableViewCell_Previews: PreviewProvider {
        private struct Container<VM: TorrentListItemViewModel>: UIViewRepresentable {
            let viewModel: VM

            init(viewModel: VM) {
                self.viewModel = viewModel
            }

            func makeUIView(
                context: UIViewRepresentableContext<Container<VM>>
            ) -> PreviewViewContainer<TorrentTableViewCell> {
                return PreviewViewContainer(TorrentTableViewCell(style: .default, reuseIdentifier: nil))
            }

            func updateUIView(
                _ uiView: PreviewViewContainer<TorrentTableViewCell>,
                context: UIViewRepresentableContext<Container<VM>>
            ) {
                uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
                uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                uiView.inner.configure(with: viewModel)
            }
        }

        static var previews: some View {
            let viewModel = MockTorrentListItemViewModel(torrentSubject: CurrentValueSubject(MockTorrent(
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
                    .previewDisplayName("Dark")
                    .previewLayout(.sizeThatFits)
                    .environment(\.colorScheme, .dark)
            }
        }
    }
#endif
