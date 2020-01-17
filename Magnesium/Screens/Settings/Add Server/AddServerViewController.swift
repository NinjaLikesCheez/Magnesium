//
//  AddServerViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import SwiftUI
import UIKit

final class AddServerViewController: UITableViewController {
    private let viewModel: AddServerViewModel

    init(viewModel: AddServerViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = "Add Server"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "text")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.types.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
        cell.textLabel?.text = viewModel.types[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectType(at: indexPath.row)
    }
}

#if DEBUG
    struct AddServerViewController_Previews: PreviewProvider {
        private struct Container: UIViewControllerRepresentable {
            let viewModel: AddServerViewModel

            func makeUIViewController(
                context: UIViewControllerRepresentableContext<Container>
            ) -> UINavigationController {
                let viewController = AddServerViewController(viewModel: viewModel)
                return UINavigationController(rootViewController: viewController)
            }

            func updateUIViewController(
                _ uiViewController: UINavigationController,
                context: UIViewControllerRepresentableContext<Container>
            ) {}
        }

        static var previews: some View {
            let viewModel = DefaultAddServerViewModel(coordinator: PreviewAddServerCoordinator())
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
