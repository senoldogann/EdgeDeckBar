import XCTest
@testable import EdgeDeck

final class AppIdentityTests: XCTestCase {
    func testIdentityConstants() {
        XCTAssertEqual(AppIdentity.name, "EdgeDeck")
        XCTAssertEqual(AppIdentity.bundleIdentifier, "dev.edgedeck.app")
        XCTAssertEqual(AppIdentity.minimumSystemVersion, "15.0")
    }
}
