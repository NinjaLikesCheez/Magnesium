//
//  AddServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Coordinator

protocol AddServerViewModel {
    var types: [String] { get }
    func didSelectType(at index: Int)
}

final class DefaultAddServerViewModel: AddServerViewModel {
    private weak var coordinator: AddServerCoordinator?

    private var serverTypes: [ServerType] = [
        .deluge,
        .transmission,
    ]

    var types: [String] {
        return serverTypes.map { $0.displayString }
    }

    init(coordinator: AddServerCoordinator) {
        self.coordinator = coordinator
    }

    func didSelectType(at index: Int) {
        coordinator?.showServerSettings(for: serverTypes[index])
    }
}
