import Coordinator
import UIKit
import ViewModel

final class NoServersViewController<VM: ViewModel>: PresentableViewController where VM.ViewEvent == NoServersViewEvent {
    private let viewModel: VM

    private lazy var stackView = with(UIStackView(arrangedSubviews: [titleLabel, bodyLabel, addServerButton])) {
        $0.axis = .vertical
        $0.spacing = 20
        $0.alignment = .center
    }

    private lazy var titleLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        $0.font = UIFont(descriptor: descriptor, size: 0)
        $0.text = L10n.Screen.NoServers.header
        $0.textAlignment = .center
    }

    private lazy var bodyLabel = with(UILabel()) {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .body)
        $0.textColor = UIColor.secondaryLabel
        $0.text = L10n.Screen.NoServers.message
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }

    private lazy var addServerButton = with(RoundedButton()) {
        $0.setTitle(L10n.Action.addServer, for: .normal)
        $0.addTarget(self, action: #selector(addSeverButtonTapped(_:)), for: .touchUpInside)
    }

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
    private func addSeverButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.addServerSelected)
    }
}
