import Foundation

enum ClinicianAuth {
    static let pin = "1234"

    static func validate(_ input: String) -> Bool {
        input == pin
    }
}
