import Coordinator
import UIKit
import ViewModel

final class AddServerViewController<VM: ViewModel>: PresentableTableViewController
    where VM.ViewEvent == AddServerViewEvent, VM.ViewValues == AddServerViewValues
{ // swiftlint:disable:this opening_brace
    private let viewModel: VM

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = L10n.Screen.AddServer.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "text")
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.values.types.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
        cell.textLabel?.text = viewModel.values.types[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.send(.typeSelected(index: indexPath.row))
    }
}
