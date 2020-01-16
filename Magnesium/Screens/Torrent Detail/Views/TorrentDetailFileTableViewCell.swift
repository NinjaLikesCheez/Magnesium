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
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
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
        contentView.addSubview(sizeLabel)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        progressLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        progressLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -8),

            progressLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),

            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            sizeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

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
        viewModel.size
            .map { text -> String? in text }
            .assign(to: \.text, on: sizeLabel)
            .store(in: &observers)

        viewModel.progress
            .map { text -> String? in text }
            .assign(to: \.text, on: progressLabel)
            .store(in: &observers)
        // swiftlint:enable array_init
    }
}

#if DEBUG
    struct TorrentDetailFileTableViewCell_Previews: PreviewProvider {
        private struct Container: UIViewRepresentable {
            var viewModel: AnyTorrentDetailFileViewModel

            func makeUIView(
                context: UIViewRepresentableContext<Container>
            ) -> PreviewViewContainer<TorrentDetailFileTableViewCell> {
                return PreviewViewContainer(TorrentDetailFileTableViewCell(style: .default, reuseIdentifier: nil))
            }

            func updateUIView(
                _ uiView: PreviewViewContainer<TorrentDetailFileTableViewCell>,
                context: UIViewRepresentableContext<Container>
            ) {
                uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
                uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                uiView.inner.configure(with: viewModel, isLastRow: false)
            }
        }

        private struct ViewModel: TorrentDetailFileViewModel, Hashable {
            let id = UUID()
            var name: String = "file.rar"
            var size: AnyPublisher<String, Never> = Just("50.0 MB").eraseToAnyPublisher()
            var progress: AnyPublisher<String, Never> = Just("100%").eraseToAnyPublisher()

            static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
                return lhs.id == rhs.id
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }

        static var previews: some View {
            let viewModel = ViewModel().eraseToAny()
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
