import Foundation
import XCTest
@testable import EdgeDeck

final class ApplicationFilterTests: XCTestCase {
    let app1 = ApplicationDescriptor(
        bundleIdentifier: "com.apple.Safari",
        displayName: "Safari",
        applicationURL: URL(fileURLWithPath: "/Applications/Safari.app")
    )
    let app2 = ApplicationDescriptor(
        bundleIdentifier: "com.apple.Notes",
        displayName: "Notes",
        applicationURL: URL(fileURLWithPath: "/Applications/Notes.app")
    )
    let app3 = ApplicationDescriptor(
        bundleIdentifier: "com.apple.calculator",
        displayName: "Calculator",
        applicationURL: URL(fileURLWithPath: "/System/Applications/Calculator.app")
    )

    func testEmptyQueryReturnsAllSorted() {
        let apps = [app1, app2, app3]
        let filtered = filterApplications(applications: apps, query: "")
        XCTAssertEqual(filtered.map(\.displayName), ["Calculator", "Notes", "Safari"])
    }

    func testCaseInsensitiveSearch() {
        let apps = [app1, app2, app3]
        let filtered = filterApplications(applications: apps, query: "saf")
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.bundleIdentifier, "com.apple.Safari")
    }

    func testNoMatchReturnsEmpty() {
        let apps = [app1, app2, app3]
        let filtered = filterApplications(applications: apps, query: "nonexistentapp")
        XCTAssertTrue(filtered.isEmpty)
    }
}
