//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

final class EmptyTorrentListViewModel: TorrentListViewModel {
    private let preferences: Preferences
    private var observers = [AnyCancellable]()
    weak var coordinator: TorrentListCoordinator?

    init(coordinator: TorrentListCoordinator, preferences: Preferences) {
        self.coordinator = coordinator
        self.preferences = preferences
        preferences.valueUpdatedPublisher(for: PreferenceKeys.servers)
            .sink { [weak self] _ in self?.serversChanged() }
            .store(in: &observers)
    }

    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> {
        return Just([]).eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func didSelectItem(at index: Int) {
        // noop
    }

    private func serversChanged() {
        coordinator?.showListForSelectedServer()
    }
}
