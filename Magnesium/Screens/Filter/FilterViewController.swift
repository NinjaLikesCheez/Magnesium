//
//  FilterViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-30.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

final class FilterViewController<VM: ViewModel>: UITableViewController
    where VM.ViewEvent == FilterViewEvent, VM.ViewState == FilterViewState {
    private let viewModel: VM
    private var dataSource: UITableViewDiffableDataSource<FilterSection.SectionType, FilterItem>!
    private var observers = [AnyCancellable]()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        navigationItem.title = NSLocalizedString("filter_screen_title", comment: "Filter")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(_:))
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(FilterItemTableViewCell.self, forCellReuseIdentifier: "cell")

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case let .sort(value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("filter_option_sort", comment: "Sort")
                cell.detailTextLabel?.text = value
                cell.accessoryType = .disclosureIndicator
                return cell
            case let .state(value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("filter_option_state", comment: "State")
                cell.detailTextLabel?.text = value
                cell.accessoryType = .disclosureIndicator
                return cell
            case let .label(value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("filter_option_label", comment: "Label")
                cell.detailTextLabel?.text = value
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

    private func update(sections: [FilterSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<FilterSection.SectionType, FilterItem>()
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        switch dataSource.itemIdentifier(for: indexPath) {
        case .sort:
            viewModel.handle(.sortSelected(source: .view(cell, rect: cell.bounds)))
        case .state:
            viewModel.handle(.stateSelected(source: .view(cell, rect: cell.bounds)))
        case .label:
            viewModel.handle(.labelSelected(source: .view(cell, rect: cell.bounds)))
        case .none:
            break
        }
    }
}
