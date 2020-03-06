import Combine
import UIKit

final class StatusView: UIView {
    private var observers = [AnyCancellable]()

    private lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
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

    func configure(download: AnyPublisher<String, Never>, upload: AnyPublisher<String, Never>) {
        observers = []
        Publishers.CombineLatest(download, upload)
            .map { "\($0) \($1)" }
            .asOptional()
            .assign(to: \.text, on: speedLabel)
            .store(in: &observers)
    }
}
