//
//  TorrentDetailFileTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class TorrentDetailFileTableViewCell: UITableViewCell {
    private var observers = [AnyCancellable]()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .body)
        return label
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        progressLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            progressLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            progressLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),

            separatorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        ])
    }

    func configure<VM: TorrentDetailFileViewModel>(with viewModel: VM, isLastRow: Bool) {
        nameLabel.text = viewModel.name
        separatorView.isHidden = isLastRow

        // swiftlint:disable array_init
        viewModel.progress
            .map { text -> String? in text }
            .assign(to: \.text, on: progressLabel)
            .store(in: &observers)
        // swiftlint:enable array_init
    }
}

#if DEBUG
    struct TorrentDetailFileTableViewCell_Previews: PreviewProvider {
        private struct Container<VM: TorrentDetailFileViewModel>: UIViewRepresentable {
            let viewModel: VM

            init(viewModel: VM) {
                self.viewModel = viewModel
            }

            func makeUIView(
                context: UIViewRepresentableContext<Container<VM>>
            ) -> PreviewViewContainer<TorrentDetailFileTableViewCell> {
                return PreviewViewContainer(TorrentDetailFileTableViewCell(style: .default, reuseIdentifier: nil))
            }

            func updateUIView(
                _ uiView: PreviewViewContainer<TorrentDetailFileTableViewCell>,
                context: UIViewRepresentableContext<Container<VM>>
            ) {
                uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
                uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                uiView.inner.configure(with: viewModel, isLastRow: false)
            }
        }

        static var previews: some View {
            let viewModel = MockTorrentDetailFileViewModel(fileSubject: CurrentValueSubject(MockTorrentFile(
                name: "file.rar",
                size: 50 * 1024 * 1024,
                downloaded: 25 * 1024 * 1024
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
