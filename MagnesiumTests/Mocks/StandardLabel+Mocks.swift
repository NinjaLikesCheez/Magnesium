@testable import Magnesium

extension StandardLabel {
    static func mock(name: String = "", count: Int = 0) -> Self {
        .init(name: name, count: count)
    }
}
