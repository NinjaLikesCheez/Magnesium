//
//  AddDelugeServerViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class AddDelugeServerViewController: UITableViewController {
    private enum Row: Int, CaseIterable {
        case name
        case server
        case password
    }

    private let viewModel: AddDelugeServerViewModel
    private let nameCell = TextInputTableViewCell()
    private let serverCell = TextInputTableViewCell()
    private let passwordCell = TextInputTableViewCell()
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

    init(viewModel: AddDelugeServerViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        navigationItem.title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        nameCell.configure(with: viewModel.nameViewModel)
        serverCell.configure(with: viewModel.serverViewModel)
        passwordCell.configure(with: viewModel.passwordViewModel)

        nameCell.proceedToNextInput
            .sink { [weak self] _ in
                self?.tableView.selectRow(
                    at: IndexPath(row: Row.server.rawValue, section: 0),
                    animated: true,
                    scrollPosition: .none
                )
            }
            .store(in: &observers)

        serverCell.proceedToNextInput
            .sink { [weak self] _ in
                self?.tableView.selectRow(
                    at: IndexPath(row: Row.password.rawValue, section: 0),
                    animated: true,
                    scrollPosition: .none
                )
            }
            .store(in: &observers)

        passwordCell.proceedToNextInput
            .sink { [weak self] _ in
                self?.performSave()
            }
            .store(in: &observers)

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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Row(rawValue: indexPath.row) {
        case .name:
            return nameCell
        case .server:
            return serverCell
        case .password:
            return passwordCell
        case .none:
            return UITableViewCell()
        }
    }

    @objc
    private func performSave() {
        viewModel.didSelectSave()
    }

    private func isLoadingChanged(_ isLoading: Bool) {
        view.endEditing(true)
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        navigationItem.rightBarButtonItem = isLoading ? loadingBarButtonItem : saveBarButtonItem
        tableView.isUserInteractionEnabled = !isLoading
    }
}

#if DEBUG
    struct AddDelugeServerViewController_Previews: PreviewProvider {
        private struct Container<VM: AddDelugeServerViewModel>: UIViewControllerRepresentable {
            private let viewModel: VM

            init(viewModel: VM) {
                self.viewModel = viewModel
            }

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container<VM>>
            ) -> UINavigationController {
                let viewController = AddDelugeServerViewController(viewModel: viewModel)
                return UINavigationController(rootViewController: viewController)
            }

            func updateUIViewController(
                _ uiViewController: UINavigationController,
                context: UIViewControllerRepresentableContext<Container<VM>>
            ) {}
        }

        static var previews: some View {
            let viewModel = MockAddDelugeServerViewModel()

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
