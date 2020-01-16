//
//  TorrentDetailInfoTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class TorrentDetailInfoTableViewCell: UITableViewCell {
    private var observers = [AnyCancellable]()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
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
        contentView.addSubview(valueLabel)
        contentView.addSubview(separatorView)
    }

    private func setupLayoutConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),

            separatorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        ])
    }

    func configure(with viewModel: TorrentDetailInfoViewModel, isLastRow: Bool) {
        nameLabel.text = viewModel.name
        // swiftlint:disable:next array_init
        viewModel.value
            .map { text -> String? in text }
            .assign(to: \.text, on: valueLabel)
            .store(in: &observers)
        separatorView.isHidden = isLastRow
    }
}

#if DEBUG
    struct TorrentDetailInfoTableViewCell_Previews: PreviewProvider {
        private struct Container: UIViewRepresentable {
            let viewModel: TorrentDetailInfoViewModel

            func makeUIView(
                context: UIViewRepresentableContext<Container>
            ) -> PreviewViewContainer<TorrentDetailInfoTableViewCell> {
                return PreviewViewContainer(TorrentDetailInfoTableViewCell(style: .default, reuseIdentifier: nil))
            }

            func updateUIView(
                _ uiView: PreviewViewContainer<TorrentDetailInfoTableViewCell>,
                context: UIViewRepresentableContext<Container>
            ) {
                uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
                uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                uiView.inner.configure(with: viewModel, isLastRow: false)
            }
        }

        static var previews: some View {
            let viewModel = TorrentDetailInfoViewModel(name: "Downloaded", value: Just("1.4 GB").eraseToAnyPublisher())
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
