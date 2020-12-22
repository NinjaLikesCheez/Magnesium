import UIKit

final class TorrentDetailTrackerTableViewCell: UITableViewCell {
    private lazy var trackerLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.numberOfLines = 0
    }

    private lazy var separatorView = with(UIView()) {
        $0.backgroundColor = .separator
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none

        contentView.addSubview(trackerLabel)
        contentView.addSubview(separatorView)

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
