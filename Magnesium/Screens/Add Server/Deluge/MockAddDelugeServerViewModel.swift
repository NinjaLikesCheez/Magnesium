//
//  MockAddDelugeServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-13.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

struct MockAddDelugeServerViewModel: AddDelugeServerViewModel {
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSaveButtonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private var observers = [AnyCancellable]()

    var title: String {
        return "Add Server"
    }

    var saveButtonTitle: String {
        return "Add"
    }

    var isLoading: AnyPublisher<Bool, Never> {
        return isLoadingSubject
            .ui()
            .eraseToAnyPublisher()
    }

    var isSaveButtonEnabled: AnyPublisher<Bool, Never> {
        return isSaveButtonEnabledSubject
            .ui()
            .eraseToAnyPublisher()
    }

    // swiftlint:disable identifier_name
    let _nameViewModel = DefaultTextInputTableViewCellViewModel(
        name: "name",
        placeholder: "Deluge",
        value: CurrentValueSubject(nil),
        returnKeyType: .next
    )

    let _serverViewModel = DefaultTextInputTableViewCellViewModel(
        name: "server",
        placeholder: "https://example.com",
        value: CurrentValueSubject(nil),
        keyboardType: .URL,
        returnKeyType: .next,
        autocapitalizationType: .none
    )

    let _passwordViewModel = DefaultTextInputTableViewCellViewModel(
        name: "password",
        placeholder: "password",
        value: CurrentValueSubject(nil),
        isSecure: true,
        returnKeyType: .send
    )
    // swiftlint:enable identifier_name

    var nameViewModel: TextInputTableViewCellViewModel {
        return _nameViewModel
    }

    var serverViewModel: TextInputTableViewCellViewModel {
        return _serverViewModel
    }

    var passwordViewModel: TextInputTableViewCellViewModel {
        return _passwordViewModel
    }

    init() {
        nameViewModel.value
            .combineLatest(serverViewModel.value, passwordViewModel.value)
            .map { name, server, password in
                guard let name = name, let server = server, let password = password else { return false }
                return !name.isEmpty && !server.isEmpty && URL(string: server) != nil && !password.isEmpty
            }
            .removeDuplicates()
            .assign(to: \.value, on: isSaveButtonEnabledSubject)
            .store(in: &observers)

        for viewModel in [_nameViewModel, _serverViewModel, _passwordViewModel] {
            isLoadingSubject
                .map { !$0 }
                .assign(to: \.value, on: viewModel.isEnabledSubject)
                .store(in: &observers)
        }
    }

    func didSelectSave() {
        guard isSaveButtonEnabledSubject.value else { return }
        isLoadingSubject.send(true)
    }
}
