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

final class SettingsViewController: UITableViewController {
    private class DataSource: UITableViewDiffableDataSource<Section, Row> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .servers:
                return "Servers"
            }
        }
    }
    private enum Section: Hashable {
        case servers
    }

    private enum Row: Hashable {
        case server(id: AnyHashable, name: String)
        case addServer
    }

    private let viewModel: SettingsViewModel
    private var observers = [AnyCancellable]()
    private var dataSource: DataSource!

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(closeButtonTapped(_:)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.cellLayoutMarginsFollowReadableWidth = true

        dataSource = DataSource(tableView: tableView) { _, _, item in
            switch item {
            case let .server(id: _, name: name):
                // TODO: custom cell
                let cell = UITableViewCell(style: .default, reuseIdentifier: "text")
                cell.textLabel?.text = name
                cell.accessoryType = .disclosureIndicator
                return cell
            case .addServer:
                // TODO: custom cell
                let cell = UITableViewCell(style: .default, reuseIdentifier: "text")
                cell.textLabel?.text = "Add Server"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.servers
            .sink { [weak self] servers in
                self?.update(servers: servers)
            }
            .store(in: &observers)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(servers: [(id: AnyHashable, name: String)]?) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([Section.servers])
        snapshot.appendItems(servers?.map { Row.server(id: $0.0, name: $0.1) } ?? [], toSection: .servers)
        snapshot.appendItems([Row.addServer], toSection: .servers)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    @objc
    private func closeButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.didSelectClose()
    }

    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
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

            init(viewModel: SettingsViewModel) {
                self.viewModel = viewModel
            }

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container>
            ) -> UINavigationController {
                let viewController = SettingsViewController(viewModel: viewModel)
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.navigationBar.prefersLargeTitles = true
                return navigationController
            }

            func updateUIViewController(
                _ uiViewController: UINavigationController,
                context: UIViewControllerRepresentableContext<Container>
            ) {}
        }

        static var previews: some View {
            let viewModel = DefaultSettingsViewModel(preferences: NoopPreferences())
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
