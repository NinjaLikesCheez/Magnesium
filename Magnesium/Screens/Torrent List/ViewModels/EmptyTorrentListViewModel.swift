//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import ViewModel

final class EmptyTorrentListViewModel: ViewModel, EventEmitter {
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)

    lazy var state = TorrentListViewState(
        showAddButton: false,
        items: Just([]).eraseToAnyPublisher(),
        isLoading: isLoadingSubject.eraseToAnyPublisher()
    )

    var events: AnyPublisher<TorrentListEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: TorrentListViewEvent) {
        switch event {
        case .refresh:
            isLoadingSubject.send(false)
        case let .filterSelected(source: source):
            eventSubject.send(.filter(source: source))
        case .settingsSelected:
            eventSubject.send(.settings)
        case .addSelected, .itemSelected:
            break
        }
    }
}
