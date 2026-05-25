import Foundation

final class PrescriptionStore {
    static let shared = PrescriptionStore(defaults: .standard)

    private let defaults: UserDefaults
    private let key = "musicarc.prescription.v1"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> Prescription? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Prescription.self, from: data)
    }

    func save(_ prescription: Prescription) throws {
        let data = try JSONEncoder().encode(prescription)
        defaults.set(data, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
