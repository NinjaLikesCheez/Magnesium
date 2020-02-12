//
//  SettingsViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

final class SettingsViewController<VM: ViewModel>: UITableViewController
    where VM.ViewEvent == SettingsViewEvent, VM.ViewState == SettingsViewState {
    private class DataSource: UITableViewDiffableDataSource<SettingsSection.SectionType, SettingsItem> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .changeServer:
                return nil
            case .servers:
                return NSLocalizedString("settings_section_servers", comment: "Servers")
            case .general:
                return NSLocalizedString("settings_section_general", comment: "General")
            }
        }
    }

    private let viewModel: VM
    private var observers = [AnyCancellable]()
    private var dataSource: DataSource!

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = NSLocalizedString("settings_screen_title", comment: "Settings")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(_:))
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
                cell.textLabel?.text = NSLocalizedString("settings_option_current_server", comment: "Current Server")
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
                cell.textLabel?.text = NSLocalizedString("settings_option_add_server", comment: "Add Server")
                cell.accessoryType = .disclosureIndicator
                return cell
            case let .refreshInterval(current: current):
                var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "detail")
                if cell == nil {
                    cell = UITableViewCell(style: .value1, reuseIdentifier: "detail")
                }
                cell.textLabel?.text = NSLocalizedString(
                    "settings_option_refresh_interval",
                    comment: "Refresh Interval"
                )
                cell.detailTextLabel?.text = current
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.state.sections
            .sink { [weak self] sections in
                self?.update(sections: sections)
            }
            .store(in: &observers)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(sections: [SettingsSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection.SectionType, SettingsItem>()
        for section in sections {
            snapshot.appendSections([section.type])
            snapshot.appendItems(section.items, toSection: section.type)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @objc
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.doneSelected)
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
        case .changeServer:
            tableView.deselectRow(at: indexPath, animated: false)
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            viewModel.handle(.changeServerSelected(source: .view(cell, rect: cell.bounds)))
        case .server:
            viewModel.handle(.serverSelected(index: indexPath.row))
        case .addServer:
            viewModel.handle(.addServerSelected)
        case .refreshInterval:
            viewModel.handle(.refreshIntervalSelected)
        case .none:
            break
        }
    }
}
