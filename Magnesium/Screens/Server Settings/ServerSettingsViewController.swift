import Combine
import Coordinator
import UIKit
import ViewModel

// swiftlint:disable:next line_length
final class ServerSettingsViewController<VM: ViewModel>: PresentableTableViewController where VM.ViewEvent == ServerSettingsViewEvent, VM.ViewValues == ServerSettingsViewValues {
    private enum Section: Int {
        case settings
        case delete
    }

    private let viewModel: VM
    private var cancellables = Set<AnyCancellable>()

    private lazy var saveBarButtonItem = UIBarButtonItem(
        title: viewModel.values.saveButtonTitle,
        style: .done,
        target: self,
        action: #selector(performSave)
    )

    private lazy var loadingBarButtonItem: UIBarButtonItem = {
        let activityView = UIActivityIndicatorView()
        activityView.startAnimating()
        return UIBarButtonItem(customView: activityView)
    }()

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        isModalInPresentation = true
        navigationItem.title = viewModel.values.title
        navigationItem.largeTitleDisplayMode = .never
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: "textInput")
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: "button")

        viewModel.values.isLoading.sink { [weak self] isLoading in
            self?.isLoadingChanged(isLoading)
        }.store(in: &cancellables)

        viewModel.values.isSaveButtonEnabled
            .assign(to: \.isEnabled, on: saveBarButtonItem)
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = .init(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonTapped(_:))
            )
        }
    }

    @objc
    private func cancelButtonTapped(_ sender: UIBarButtonItem) {
        viewModel.send(.cancelSelected)
    }

    @objc
    private func performSave() {
        viewModel.send(.saveSelected)
    }

    private func isLoadingChanged(_ isLoading: Bool) {
        view.endEditing(true)
        navigationItem.hidesBackButton = isLoading
        navigationItem.rightBarButtonItem = isLoading ? loadingBarButtonItem : saveBarButtonItem
        tableView.isUserInteractionEnabled = !isLoading
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.values.canDelete ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .settings:
            return viewModel.values.inputs.count
        case .delete:
            return 1
        case .none:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .settings:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "textInput", for: indexPath)
                as? TextInputTableViewCell
            else {
                return .init()
            }

            cell.configure(with: viewModel.values.inputs[indexPath.row])
            cell.proceedToNextInput = { [weak self] in
                guard let strongSelf = self else { return }
                if indexPath.row < strongSelf.viewModel.values.inputs.count - 1 {
                    let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                    strongSelf.tableView.selectRow(at: nextIndexPath, animated: true, scrollPosition: .none)
                } else {
                    strongSelf.performSave()
                }
            }
            return cell
        case .delete:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "button", for: indexPath)
                as? ButtonTableViewCell
            else {
                return .init()
            }

            let configuration = ButtonTableViewCell.Configuration(
                style: .destructive,
                fontWeight: .semibold,
                alignment: .center
            )
            cell.configure(text: L10n.delete, configuration: configuration)
            return cell
        case .none:
            return .init()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Section.delete.rawValue {
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            viewModel.send(.deleteSelected(source: .view(cell, rect: cell.bounds)))
        }
    }
}
