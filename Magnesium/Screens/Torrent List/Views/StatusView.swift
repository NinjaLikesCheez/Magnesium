import Combine
import UIKit

final class StatusView: UIView {
    private var cancellables = Set<AnyCancellable>()

    private lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        addSubview(speedLabel)
    }

    private func setupLayoutConstraints() {
        speedLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            speedLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            speedLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            speedLabel.topAnchor.constraint(equalTo: topAnchor),
            speedLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(status: AnyPublisher<String, Never>) {
        cancellables.removeAll()
        status
            .asOptional()
            .assign(to: \.text, on: speedLabel)
            .store(in: &cancellables)
    }
}
