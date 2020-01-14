//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Navigator
import Preferences

final class EmptyTorrentListViewModel: TorrentListViewModel, TorrentListViewModelExt {
    private var observers = [AnyCancellable]()
    let preferences: Preferences
    var navigator: Navigator?

    init(preferences: Preferences) {
        self.preferences = preferences
        preferences.valueUpdatedPublisher(for: PreferenceKeys.servers)
            .sink { [weak self] _ in self?.serversChanged() }
            .store(in: &observers)
    }

    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> {
        return Just([]).eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Never, Error> {
        // noop
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func didSelectItem(at index: Int) {
        // noop
    }

    private func serversChanged() {
        navigator?.showFirstServer(preferences: preferences)
    }
}
