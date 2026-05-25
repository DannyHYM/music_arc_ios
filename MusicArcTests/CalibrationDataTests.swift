import XCTest
@testable import MusicArc

final class CalibrationDataTests: XCTestCase {
    func testIdentityRangePassesThrough() {
        let cal = CalibrationData(minHeight: 0.0, maxHeight: 1.0)
        XCTAssertEqual(cal.normalize(0.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(cal.normalize(0.0), 0.0, accuracy: 0.0001)
        XCTAssertEqual(cal.normalize(1.0), 1.0, accuracy: 0.0001)
    }

    func testNarrowRangeStretches() {
        let cal = CalibrationData(minHeight: 0.4, maxHeight: 0.6)
        XCTAssertEqual(cal.normalize(0.4), 0.0, accuracy: 0.0001)
        XCTAssertEqual(cal.normalize(0.6), 1.0, accuracy: 0.0001)
        XCTAssertEqual(cal.normalize(0.5), 0.5, accuracy: 0.0001)
    }

    func testValuesOutsideRangeClamp() {
        let cal = CalibrationData(minHeight: 0.2, maxHeight: 0.8)
        XCTAssertEqual(cal.normalize(-0.5), 0.0, accuracy: 0.0001)
        XCTAssertEqual(cal.normalize(2.0), 1.0, accuracy: 0.0001)
    }

    func testDegenerateRangeReturnsHalf() {
        let cal = CalibrationData(minHeight: 0.7, maxHeight: 0.3) // inverted
        XCTAssertEqual(cal.normalize(0.5), 0.5, accuracy: 0.0001)
    }

    func testEqualMinMaxReturnsHalf() {
        let cal = CalibrationData(minHeight: 0.5, maxHeight: 0.5)
        XCTAssertEqual(cal.normalize(0.5), 0.5, accuracy: 0.0001)
    }
}
