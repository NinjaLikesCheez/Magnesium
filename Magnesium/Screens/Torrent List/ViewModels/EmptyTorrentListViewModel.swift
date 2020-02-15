//
//  EmptyTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

final class EmptyTorrentListViewModel: ViewModel, EventEmitter, TorrentListProvider {
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)

    lazy var state = TorrentListViewState(
        showAddButton: false,
        showFilterButton: false,
        title: Just(L10n.torrentsScreenTitle).eraseToAnyPublisher(),
        items: Just([]).eraseToAnyPublisher(),
        isLoading: isLoadingSubject.eraseToAnyPublisher(),
        hasActiveFilters: Just(false).eraseToAnyPublisher(),
        editActionsEnabled: Just(false).eraseToAnyPublisher()
    )

    var events: AnyPublisher<TorrentListEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: TorrentListViewEvent) {
        switch event {
        case .refresh:
            isLoadingSubject.send(false)
        case .settingsSelected:
            eventSubject.send(.settings)
        default:
            break
        }
    }

    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        return nil
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        return nil
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration? {
        return nil
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> UISwipeActionsConfiguration? {
        return nil
    }
}
