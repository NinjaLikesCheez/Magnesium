//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

final class EmptyTorrentListViewModel: ViewModel, EventProducer {
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private let isLoadingSubject = PassthroughSubject<Bool, Never>()

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
        case .add, .selectItem:
            break
        case .refresh:
            isLoadingSubject.send(false)
        case .settings:
            eventSubject.send(.settings)
        }
    }
}
