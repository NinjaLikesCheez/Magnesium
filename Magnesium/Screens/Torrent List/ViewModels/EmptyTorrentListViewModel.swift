//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

final class EmptyTorrentListViewModel: TorrentListViewModel {
    var observers = [AnyCancellable]()
    var coordinator: TorrentListCoordinator?

    var showAddButton: Bool {
        return false
    }

    init(coordinator: TorrentListCoordinator) {
        self.coordinator = coordinator
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

    func addLink(_ url: String) {
        // noop
    }
}
