//
//  CurrentValueSubjectMapManager.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

class CurrentValueSubjectMapManager<K: Hashable, V> {
    typealias CurrentValueArray<T> = [CurrentValueSubject<T, Never>]
    typealias CurrentValueArraySubject<T> = CurrentValueSubject<CurrentValueArray<T>, Never>
    typealias CurrentValueMap<K: Hashable, V> = [K: CurrentValueSubject<V, Never>]
    typealias CurrentValueMapSubject<K: Hashable, V> = CurrentValueSubject<CurrentValueMap<K, V>, Never>

    private var observers = [AnyCancellable]()
    private let mapSubject = CurrentValueMapSubject<K, V>([:])
    private let sortedSubject = CurrentValueArraySubject<V>([])

    var sorted: AnyPublisher<[CurrentValueSubject<V, Never>], Never> {
        return sortedSubject.eraseToAnyPublisher()
    }

    init(sort: AnyPublisher<(CurrentValueArray<V>) -> CurrentValueArray<V>, Never>) {
        mapSubject
            .map { Array($0.values) }
            .combineLatest(sort)
            .map { $0.1($0.0) }
            .sink { [weak self] in self?.sortedSubject.value = $0 }
            .store(in: &observers)
    }

    func update(with new: [(K, V)]) {
        let newMap = new.reduce(into: CurrentValueMap()) {
            $0[$1.0] = CurrentValueSubject($1.1)
        }
        mapSubject.send(
            mapSubject.value
                .filter { newMap[$0.key] != nil }
                .merging(newMap) { current, new in
                    current.send(new.value)
                    return current
                }
        )
    }

    func subject(at index: Int) -> CurrentValueSubject<V, Never> {
        return sortedSubject.value[index]
    }
}

final class TorrentSubjectMapManager<K: Hashable, V: SortableTorrent>: CurrentValueSubjectMapManager<K, V> {
    init(preferences: Preferences) {
        let sortFunction = preferences.valuePublisher(for: PreferenceKeys.sortOption)
            .map { sort -> ((CurrentValueArray<V>) -> CurrentValueArray<V>) in
                return { TorrentSortUtil.sort($0, using: sort) }
            }
            .eraseToAnyPublisher()
        super.init(sort: sortFunction)
    }
}
