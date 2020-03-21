import Combine
import UIKit
import ViewModel

// swiftlint:disable:next line_length
final class SettingsViewController<VM: ViewModel>: UITableViewController where VM.ViewEvent == SettingsViewEvent, VM.ViewRepresentation == SettingsViewRepresentation {
    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: DataSource!

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = L10n.settingsScreenTitle
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = .init(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(_:))
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "text")

        dataSource = .init(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case let .changeServer(name):
                var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "detail")
                if cell == nil {
                    cell = .init(style: .value1, reuseIdentifier: "detail")
                }
                cell.textLabel?.text = L10n.settingsOptionCurrentServer
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
                cell.textLabel?.text = L10n.settingsOptionAddServer
                cell.accessoryType = .disclosureIndicator
                return cell
            case let .refreshInterval(current: current):
                var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "detail")
                if cell == nil {
                    cell = .init(style: .value1, reuseIdentifier: "detail")
                }
                cell.textLabel?.text = L10n.settingsOptionRefreshInterval
                cell.detailTextLabel?.text = current
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.view.sections
            .sink { [weak self] sections in
                self?.update(sections: sections)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
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
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.receive(.doneSelected)
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
        case .changeServer:
            tableView.deselectRow(at: indexPath, animated: false)
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            viewModel.receive(.changeServerSelected(source: .view(cell, rect: cell.bounds)))
        case .server:
            viewModel.receive(.serverSelected(index: indexPath.row))
        case .addServer:
            viewModel.receive(.addServerSelected)
        case .refreshInterval:
            viewModel.receive(.refreshIntervalSelected)
        case .none:
            break
        }
    }
}

private extension SettingsViewController {
    class DataSource: UITableViewDiffableDataSource<SettingsSectionType, SettingsItem> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .changeServer:
                return nil
            case .servers:
                return L10n.settingsSectionServers
            case .general:
                return L10n.settingsSectionGeneral
            }
        }
    }
}
