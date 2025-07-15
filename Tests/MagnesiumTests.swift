import Foundation
import Testing
@testable import Magnesium

@Suite("Magnesium Tests")
struct MagnesiumTests {
    @Test("Basic functionality test")
    func basicFunctionalityTest() {
        #expect(2 + 2 == 4)
    }
}
