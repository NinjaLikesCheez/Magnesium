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
    private var observers = [AnyCancellable]()

    private lazy var sortCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = "Sort"
        cell.accessoryType = .disclosureIndicator

        if let textLabel = cell.detailTextLabel {
            viewModel.state.sortOption
                .asOptional()
                .assign(to: \.text, on: textLabel)
                .store(in: &observers)
        }

        return cell
    }()

    private lazy var stateCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = "State"
        cell.accessoryType = .disclosureIndicator

        if let textLabel = cell.detailTextLabel {
            viewModel.state.state
                .asOptional()
                .assign(to: \.text, on: textLabel)
                .store(in: &observers)
        }

        return cell
    }()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        navigationItem.title = "Filter"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(_:))
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func doneButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.handle(.doneSelected)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return sortCell
        case 1:
            return stateCell
        default:
            return UITableViewCell()
        }
    }
}
