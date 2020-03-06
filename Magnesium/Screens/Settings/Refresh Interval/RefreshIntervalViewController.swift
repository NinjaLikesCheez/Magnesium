import Combine
import UIKit
import ViewModel

// swiftlint:disable:next line_length
final class RefreshIntervalViewController<VM: ViewModel>: UITableViewController where VM.ViewEvent == RefreshIntervalViewEvent, VM.ViewState == RefreshIntervalViewState {
    private let viewModel: VM
    private var observers = [AnyCancellable]()

    private lazy var cells: [UITableViewCell] = {
        return viewModel.state.options.map { state in
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = state.name
            state.isSelected
                .map { isSelected -> UITableViewCell.AccessoryType in
                    isSelected ? .checkmark : .none
                }
                .assign(to: \.accessoryType, on: cell)
                .store(in: &observers)
            return cell
        }
    }()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = L10n.refreshIntervalScreenTitle
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.handle(.optionSelected(index: indexPath.row))
    }
}
