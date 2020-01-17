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
        dataSource.apply(snapshot, animatingDifferences: false)
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

        private final class Coordinator: PreviewCoordinator, SettingsCoordinator {
            func complete() {}
            func showServerSettings(_ server: Server) {}
            func showAddServer() {}
        }

        static var previews: some View {
            let viewModel = DefaultSettingsViewModel(
                coordinator: Coordinator(),
                preferences: PreviewPreferences()
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
