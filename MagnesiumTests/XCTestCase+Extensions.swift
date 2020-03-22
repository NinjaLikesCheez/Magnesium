import XCTest

extension XCTestCase {
    func XCTAssertType(_ lhs: Any?, _ rhs: Any.Type, file: StaticString = #file, line: UInt = #line) {
        if lhs.map({ type(of: $0) }) != rhs {
            XCTFail(
                "(\(String(describing: lhs))) is not equal to (\(String(describing: rhs)))",
                file: file,
                line: line
            )
        }
    }
}
