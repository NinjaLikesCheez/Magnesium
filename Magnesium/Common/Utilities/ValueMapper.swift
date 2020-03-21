import Combine

/// A `ValueMapper` takes in key/value pairs, filters them using a filter function that can change over time, and.
/// emits the filtered values.
class ValueMapper<K: Hashable, V> {
    typealias CurrentValueArray<T> = [CurrentValueSubject<T, Never>]
    typealias CurrentValueArraySubject<T> = CurrentValueSubject<CurrentValueArray<T>, Never>
    typealias CurrentValueMap<K: Hashable, V> = [K: CurrentValueSubject<V, Never>]
    typealias CurrentValueMapSubject<K: Hashable, V> = CurrentValueSubject<CurrentValueMap<K, V>, Never>
    typealias FilterFunction = (CurrentValueArray<V>) -> CurrentValueArray<V>

    private var cancellables = Set<AnyCancellable>()
    private let mapSubject = CurrentValueMapSubject<K, V>([:])
    private let valuesSubject = CurrentValueArraySubject<V>([])
    /// A publisher that emits all values. This publisher does not perform deduplication.
    let allValues: AnyPublisher<[CurrentValueSubject<V, Never>], Never>

    /// A publisher that emits the deduplicated filtered values.
    var values: AnyPublisher<[CurrentValueSubject<V, Never>], Never> {
        valuesSubject.eraseToAnyPublisher()
    }

    /// Creates a value mapper using the given filter publisher.
    /// - Parameter filter: A publisher that emits filter functions. When this publisher emits, the values will be
    /// updated with the new filter function.
    init(filter: AnyPublisher<FilterFunction, Never>) {
        allValues = mapSubject.map { Array($0.values) }.eraseToAnyPublisher()
        mapSubject
            .removeDuplicates { $0.keys == $1.keys }
            .combineLatest(filter)
            .map { $0.1(Array($0.0.values)) }
            .subscribe(valuesSubject)
            .store(in: &cancellables)
    }

    /// Updates the values with the given key/value pairs.
    /// - Parameter new: The new key/value pairs.
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

    /// Returns the subject at a given index.
    /// - Parameter index: The requested index.
    /// - Returns: The subject at the requested index.
    func subject(at index: Int) -> CurrentValueSubject<V, Never> {
        valuesSubject.value[index]
    }
}
