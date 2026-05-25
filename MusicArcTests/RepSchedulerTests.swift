import XCTest
@testable import MusicArc

final class RepSchedulerTests: XCTestCase {
    func testGenerateProducesRequestedCount() {
        let config = GameConfig(repCount: 6, activeDuration: 4, restDuration: 3)
        let reps = RepScheduler.generate(config: config)
        XCTAssertEqual(reps.count, 6)
    }

    func testFirstRepStartsAfterCountdown() {
        let config = GameConfig(repCount: 4, activeDuration: 4, restDuration: 3)
        let reps = RepScheduler.generate(config: config)
        XCTAssertEqual(reps[0].activeStartTime, RepScheduler.countdownDuration)
    }

    func testRepsAreContiguous() {
        let config = GameConfig(repCount: 5, activeDuration: 4, restDuration: 3)
        let reps = RepScheduler.generate(config: config)

        for i in 0..<reps.count - 1 {
            XCTAssertEqual(reps[i].restEndTime, reps[i + 1].activeStartTime, accuracy: 0.0001,
                           "rep \(i) restEnd should equal rep \(i+1) activeStart")
        }
    }

    func testActivePhaseLength() {
        let config = GameConfig(repCount: 3, activeDuration: 5, restDuration: 2)
        let reps = RepScheduler.generate(config: config)
        for rep in reps {
            XCTAssertEqual(rep.activeEndTime - rep.activeStartTime, 5, accuracy: 0.0001)
            XCTAssertEqual(rep.restEndTime - rep.restStartTime, 2, accuracy: 0.0001)
        }
    }
}
