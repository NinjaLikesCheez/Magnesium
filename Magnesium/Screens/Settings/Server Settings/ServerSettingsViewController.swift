//
//  ServerSettingsViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class ServerSettingsViewController: PresentableTableViewController {
    private enum Section: Int {
        case settings
        case delete
    }

    private let viewModel: ServerSettingsViewModel
    private var observers = [AnyCancellable]()

    private lazy var saveBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            title: viewModel.saveButtonTitle,
            style: .done,
            target: self,
            action: #selector(performSave)
        )
    }()

    private lazy var loadingBarButtonItem: UIBarButtonItem = {
        let activityView = UIActivityIndicatorView()
        activityView.startAnimating()
        return UIBarButtonItem(customView: activityView)
    }()

    init(viewModel: ServerSettingsViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        isModalInPresentation = true
        navigationItem.title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never

        viewModel.isLoading
            .sink { [weak self] isLoading in
                self?.isLoadingChanged(isLoading)
            }
            .store(in: &observers)

        viewModel.isSaveButtonEnabled
            .assign(to: \.isEnabled, on: saveBarButtonItem)
            .store(in: &observers)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: "textInput")
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: "button")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.canDelete ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .settings:
            return viewModel.inputs.count
        case .delete:
            return 1
        case .none:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .settings:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "textInput", for: indexPath)
                as? TextInputTableViewCell
            else {
                return UITableViewCell()
            }

            cell.configure(with: viewModel.inputs[indexPath.row])
            cell.proceedToNextInput = { [weak self] in
                guard let strongSelf = self else { return }
                if indexPath.row < strongSelf.viewModel.inputs.count - 1 {
                    let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                    strongSelf.tableView.selectRow(at: nextIndexPath, animated: true, scrollPosition: .none)
                } else {
                    strongSelf.performSave()
                }
            }
            return cell
        case .delete:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "button", for: indexPath)
                as? ButtonTableViewCell
            else {
                return UITableViewCell()
            }

            let configuration = ButtonTableViewCell.Configuration(
                style: .destructive,
                fontWeight: .semibold,
                alignment: .center
            )
            cell.configure(text: "Delete", configuration: configuration)
            return cell
        case .none:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Section.delete.rawValue {
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            viewModel.didSelectDelete(from: .view(cell, rect: cell.bounds))
        }
    }

    @objc
    private func performSave() {
        viewModel.didSelectSave()
    }

    private func isLoadingChanged(_ isLoading: Bool) {
        view.endEditing(true)
        navigationItem.hidesBackButton = isLoading
        navigationItem.rightBarButtonItem = isLoading ? loadingBarButtonItem : saveBarButtonItem
        tableView.isUserInteractionEnabled = !isLoading
    }
}

#if DEBUG
    struct DelugeSettingsViewController_Previews: PreviewProvider {
        private struct Container: UIViewControllerRepresentable {
            let viewModel: DelugeSettingsViewModel

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container>
            ) -> UINavigationController {
                let viewController = ServerSettingsViewController(viewModel: viewModel)
                return UINavigationController(rootViewController: viewController)
            }

            func updateUIViewController(
                _ uiViewController: UINavigationController,
                context: UIViewControllerRepresentableContext<Container>
            ) {}
        }

        static var previews: some View {
            let server = Server(name: "Deluge", type: .deluge, data: Data())
            let viewModel = DelugeSettingsViewModel(
                coordinator: PreviewAddServerCoordinator(),
                preferences: PreviewPreferences(),
                server: server
            )
            return Group {
                Container(viewModel: viewModel)
                    .previewDisplayName("Light")
                Container(viewModel: viewModel)
                    .previewDisplayName("Dark")
                    .environment(\.colorScheme, .dark)
            }
        }
    }
#endif
