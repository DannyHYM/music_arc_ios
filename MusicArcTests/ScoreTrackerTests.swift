import XCTest
@testable import MusicArc

final class ScoreTrackerTests: XCTestCase {
    func testGrowthClampsAtOne() {
        let tracker = ScoreTracker()
        tracker.addGrowth(0.6)
        tracker.addGrowth(0.6)
        XCTAssertEqual(tracker.growthPercentage, 1.0, accuracy: 0.0001)
    }

    func testHealthFloor() {
        let tracker = ScoreTracker()
        tracker.penalizeHealth(2.0)
        XCTAssertEqual(tracker.treeHealth, 0.0, accuracy: 0.0001)
    }

    func testHealthCeiling() {
        let tracker = ScoreTracker()
        tracker.restoreHealth(2.0)
        XCTAssertEqual(tracker.treeHealth, 1.0, accuracy: 0.0001)
    }

    func testRestComplianceAveragesAcrossReps() {
        let tracker = ScoreTracker()
        tracker.finishRep(growth: 0.1, restCompliance: 1.0)
        tracker.finishRep(growth: 0.1, restCompliance: 0.5)
        tracker.finishRep(growth: 0.1, restCompliance: 0.0)
        XCTAssertEqual(tracker.averageRestCompliance, 0.5, accuracy: 0.0001)
    }

    func testEmptyRestComplianceDefaultsToOne() {
        let tracker = ScoreTracker()
        XCTAssertEqual(tracker.averageRestCompliance, 1.0)
    }

    func testResetClears() {
        let tracker = ScoreTracker()
        tracker.addGrowth(0.5)
        tracker.finishRep(growth: 0.5, restCompliance: 0.8)
        tracker.reset()
        XCTAssertEqual(tracker.growthPercentage, 0)
        XCTAssertEqual(tracker.completedReps, 0)
        XCTAssertEqual(tracker.treeHealth, 1.0)
    }
}
