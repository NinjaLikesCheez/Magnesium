import Combine
import UIKit

final class ToolbarInfoView: UIView {
    private var cancellables = Set<AnyCancellable>()

    private lazy var contentLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .footnote)
        $0.textColor = .secondaryLabel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(contentLabel)

        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentLabel.topAnchor.constraint(equalTo: topAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(content: UIPublisher<String>) {
        cancellables.removeAll()
        content
            .asOptional()
            .assign(to: \.text, on: contentLabel)
            .store(in: &cancellables)
    }
}
