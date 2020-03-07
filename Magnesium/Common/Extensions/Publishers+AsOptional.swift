import Combine

extension Publisher {
    func asOptional() -> Publishers.Map<Self, Self.Output?> {
        return map { Optional.some($0) }
    }
}
