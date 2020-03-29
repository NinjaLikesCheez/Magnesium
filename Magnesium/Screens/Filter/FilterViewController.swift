import Combine
import UIKit
import ViewModel

// swiftlint:disable:next line_length
final class FilterViewController<VM: ViewModel>: UITableViewController where VM.ViewEvent == FilterViewEvent, VM.ViewValues == FilterViewValues {
    private let viewModel: VM
    private var dataSource: UITableViewDiffableDataSource<FilterSectionType, FilterItem>!
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        navigationItem.title = L10n.filterScreenTitle
        navigationItem.leftBarButtonItem = .init(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(_:))
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(FilterItemTableViewCell.self, forCellReuseIdentifier: "cell")

        dataSource = .init(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case let .sort(value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = L10n.filterOptionSort
                cell.detailTextLabel?.text = value
                return cell
            case let .state(value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = L10n.filterOptionState
                cell.detailTextLabel?.text = value
                return cell
            case let .label(value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = L10n.filterOptionLabel
                cell.detailTextLabel?.text = value
                return cell
            }
        }

        tableView.dataSource = dataSource

        viewModel.values.sections
            .sink { [weak self] sections in
                self?.update(sections: sections)
            }
            .store(in: &cancellables)
    }

    private func update(sections: [FilterSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<FilterSectionType, FilterItem>()
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        switch dataSource.itemIdentifier(for: indexPath) {
        case .sort:
            viewModel.receive(.sortSelected(source: .view(cell, rect: cell.bounds)))
        case .state:
            viewModel.receive(.stateSelected(source: .view(cell, rect: cell.bounds)))
        case .label:
            viewModel.receive(.labelSelected(source: .view(cell, rect: cell.bounds)))
        case .none:
            break
        }
    }
}
