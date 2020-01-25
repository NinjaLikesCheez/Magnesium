//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

final class EmptyTorrentListViewModel: TorrentListViewModel {
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    let showAddButton = false

    var events: AnyPublisher<TorrentListEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> {
        return Just([]).eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func didSelectAdd(from source: PopoverSource) {
        eventSubject.send(.add(source: source))
    }

    func didSelectItem(at index: Int) {
        // noop
    }

    func didSelectSettings() {
        eventSubject.send(.settings)
    }

    func addLink(_ url: String) {
        // noop
    }
}
