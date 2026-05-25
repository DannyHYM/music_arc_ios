import XCTest
@testable import MusicArc

final class PrescriptionStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "musicarc.tests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testLoadReturnsNilWhenEmpty() {
        let store = PrescriptionStore(defaults: defaults)
        XCTAssertNil(store.load())
    }

    func testRoundTripPreservesFields() throws {
        let store = PrescriptionStore(defaults: defaults)
        let config = GameConfig(
            repCount: 12,
            activeDuration: 6,
            restDuration: 5,
            sunlightThreshold: 0.75,
            restThreshold: 0.25,
            inputMode: .camera,
            trackingArm: .left
        )
        let original = Prescription(config: config, lastUpdated: Date(timeIntervalSince1970: 100_000))

        try store.save(original)
        let loaded = store.load()

        XCTAssertEqual(loaded?.config.repCount, 12)
        XCTAssertEqual(loaded?.config.activeDuration, 6)
        XCTAssertEqual(loaded?.config.restDuration, 5)
        XCTAssertEqual(loaded?.config.inputMode, .camera)
        XCTAssertEqual(loaded?.config.trackingArm, .left)
        XCTAssertEqual(loaded?.lastUpdated.timeIntervalSince1970, 100_000)
    }

    func testResetClears() throws {
        let store = PrescriptionStore(defaults: defaults)
        try store.save(.default)
        XCTAssertNotNil(store.load())
        store.reset()
        XCTAssertNil(store.load())
    }
}
