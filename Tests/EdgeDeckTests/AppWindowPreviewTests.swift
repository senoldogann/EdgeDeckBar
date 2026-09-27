import CoreGraphics
import Foundation
import XCTest
@testable import EdgeDeck

final class AppWindowPreviewTests: XCTestCase {
    func testAppWindowInfoCreation() {
        let bounds = CGRect(x: 100.0, y: 150.0, width: 800.0, height: 600.0)
        let info = AppWindowInfo(
            id: 1234,
            title: "Safari — Apple",
            bounds: bounds,
            ownerPID: 5678,
            ownerName: "Safari"
        )

        XCTAssertEqual(info.id, 1234)
        XCTAssertEqual(info.title, "Safari — Apple")
        XCTAssertEqual(info.bounds.width, 800.0)
        XCTAssertEqual(info.bounds.height, 600.0)
        XCTAssertEqual(info.ownerPID, 5678)
        XCTAssertEqual(info.ownerName, "Safari")
    }

    func testAppWindowPreviewServiceNonEmptyQuery() {
        let service = AppWindowPreviewService()
        // Querying non-existent bundle ID returns empty without crashing
        let emptyResult = service.windows(
            forBundleIdentifier: "non.existent.bundle.identifier.12345",
            appName: "NonExistentAppXYZ"
        )
        XCTAssertTrue(emptyResult.isEmpty)
    }
}
