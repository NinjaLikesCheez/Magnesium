import Combine

extension Publisher {
    func asOptional() -> Publishers.Map<Self, Self.Output?> {
        map { Optional.some($0) }
    }
}
