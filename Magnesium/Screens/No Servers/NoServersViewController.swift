//
//  NoServersViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Coordinator
import UIKit
import ViewModel

final class NoServersViewController<VM: ViewModel>: PresentableViewController where VM.ViewEvent == NoServersViewEvent {
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
        label.text = NSLocalizedString("no_servers_title", comment: "No Servers")
        label.textAlignment = .center
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = UIColor.secondaryLabel
        label.text = NSLocalizedString(
            "no_servers_body",
            comment: "You'll need to add a server before you can start using Magnesium."
        )
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var addServerButton: UIButton = {
        let button = AddButton()
        button.addTarget(self, action: #selector(addSeverButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var settingsBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped(_:))
        )
    }()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Magnesium"
        navigationItem.leftBarButtonItem = settingsBarButtonItem
    }

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
        stackView.addArrangedSubview(addServerButton)
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
        viewModel.handle(.settingsSelected)
    }

    @objc
    private func addSeverButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.addServerSelected)
    }
}

private final class AddButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }

    init() {
        super.init(frame: .zero)
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        backgroundColor = .systemBlue
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        titleLabel?.font = UIFont(descriptor: descriptor, size: 0)
        setTitle(NSLocalizedString("action_add_server", comment: "Add Server"), for: .normal)
        isHighlighted = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.mask = {
            let mask = CAShapeLayer()
            mask.frame = bounds
            mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
            return mask
        }()
    }
}
