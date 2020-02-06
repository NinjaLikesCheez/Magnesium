//
//  ValueMapper.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-31.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

class ValueMapper<K: Hashable, V> {
    typealias CurrentValueArray<T> = [CurrentValueSubject<T, Never>]
    typealias CurrentValueArraySubject<T> = CurrentValueSubject<CurrentValueArray<T>, Never>
    typealias CurrentValueMap<K: Hashable, V> = [K: CurrentValueSubject<V, Never>]
    typealias CurrentValueMapSubject<K: Hashable, V> = CurrentValueSubject<CurrentValueMap<K, V>, Never>
    typealias FilterFunction = (CurrentValueArray<V>) -> CurrentValueArray<V>

    private var observers = [AnyCancellable]()
    private let mapSubject = CurrentValueMapSubject<K, V>([:])
    private let valuesSubject = CurrentValueArraySubject<V>([])

    var values: AnyPublisher<[CurrentValueSubject<V, Never>], Never> {
        return valuesSubject.eraseToAnyPublisher()
    }

    init(filter: AnyPublisher<FilterFunction, Never>) {
        mapSubject
            .map { Array($0.values) }
            .combineLatest(filter)
            .map { $0.1($0.0) }
            .sink { [weak self] in self?.valuesSubject.value = $0 }
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
        return valuesSubject.value[index]
    }
}
