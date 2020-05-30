import Coordinator
import UIKit
import ViewModel

// swiftlint:disable:next line_length
final class ServerErrorViewController<VM: ViewModel>: PresentableViewController where VM.ViewEvent == ServerErrorViewEvent {
    private let viewModel: VM

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.text = L10n.serverErrorTitle
        label.textAlignment = .center
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = UIColor.secondaryLabel
        label.text = L10n.serverErrorBody
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var editServerButton: UIButton = {
        let button = RoundedButton()
        button.setTitle(L10n.editServer, for: .normal)
        button.addTarget(self, action: #selector(editServerButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var settingsBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "gear"),
        style: .plain,
        target: self,
        action: #selector(settingsButtonTapped(_:))
    )

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Magnesium"
        navigationItem.leftBarButtonItem = settingsBarButtonItem
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayoutConstraints()
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(editServerButton)
        view.addSubview(stackView)
    }

    private func setupLayoutConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            stackView.widthAnchor.constraint(equalToConstant: 320).withPriority(.defaultHigh),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc
    private func settingsButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.settingsSelected)
    }

    @objc
    private func editServerButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.editServerSelected)
    }
}
