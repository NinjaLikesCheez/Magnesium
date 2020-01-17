//
//  SettingsViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class SettingsViewController: PresentableTableViewController {
    private class DataSource: UITableViewDiffableDataSource<SettingsSectionType, SettingsItem> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .changeServer:
                return nil
            case .servers:
                return "Servers"
            }
        }
    }

    private let viewModel: SettingsViewModel
    private var observers = [AnyCancellable]()
    private var dataSource: DataSource!

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(closeButtonTapped(_:))
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "text")

        dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case let .changeServer(name):
                var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "detail")
                if cell == nil {
                    cell = UITableViewCell(style: .value1, reuseIdentifier: "detail")
                }
                cell.textLabel?.text = "Selected Server"
                cell.detailTextLabel?.text = name
                cell.accessoryType = .disclosureIndicator
                return cell
            case let .server(id: _, name: name):
                let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
                cell.textLabel?.text = name
                cell.accessoryType = .disclosureIndicator
                return cell
            case .addServer:
                let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
                cell.textLabel?.text = "Add Server"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.sections
            .sink { [weak self] sections in
                self?.update(sections: sections)
            }
            .store(in: &observers)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(sections: [SettingsSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSectionType, SettingsItem>()
        for section in sections {
            snapshot.appendSections([section.type])
            snapshot.appendItems(section.items, toSection: section.type)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @objc
    private func closeButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.didSelectClose()
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
        case .changeServer:
            tableView.deselectRow(at: indexPath, animated: false)
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            viewModel.didSelectChangeServer(from: .view(cell, rect: cell.bounds))
        case .server:
            viewModel.didSelectServer(at: indexPath.row)
        case .addServer:
            viewModel.didSelectAddServer()
        case .none:
            break
        }
    }
}

#if DEBUG
    struct SettingsViewController_Previews: PreviewProvider {
        private struct Container: UIViewControllerRepresentable {
            let viewModel: SettingsViewModel

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container>
            ) -> UINavigationController {
                let viewController = SettingsViewController(viewModel: viewModel)
                return UINavigationController(rootViewController: viewController)
            }

            func updateUIViewController(
                _ uiViewController: UINavigationController,
                context: UIViewControllerRepresentableContext<Container>
            ) {}
        }

        private final class ViewModel: SettingsViewModel {
            var coordinator: SettingsCoordinator?

            var sections: AnyPublisher<[SettingsSection], Never> = Just([
                SettingsSection(type: .changeServer, items: [.changeServer("Desktop")]),
                SettingsSection(type: .servers, items: [
                    .server(id: 0, name: "Desktop"),
                    .addServer,
                ]),
            ]).eraseToAnyPublisher()

            func didSelectChangeServer(from source: PopoverSource) {}
            func didSelectServer(at index: Int) {}
            func didSelectAddServer() {}
        }

        static var previews: some View {
            let viewModel = ViewModel()
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
