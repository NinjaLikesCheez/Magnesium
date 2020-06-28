import Combine

struct FilterViewValues {
    var sections: AnyPublisher<[FilterSection], Never>
}
