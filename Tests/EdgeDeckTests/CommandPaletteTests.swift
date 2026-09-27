import SwiftUI
import XCTest
@testable import EdgeDeck

final class CommandPaletteTests: XCTestCase {
    @MainActor
    func testCommandPaletteItemCreation() {
        var actionExecuted = false
        let item = CommandPaletteItem(
            id: "test-lock",
            title: "Lock Screen",
            subtitle: "Lock current user session",
            iconSystemName: "lock.fill",
            iconColor: .red,
            category: .quickActions,
            action: {
                actionExecuted = true
            }
        )

        XCTAssertEqual(item.id, "test-lock")
        XCTAssertEqual(item.title, "Lock Screen")
        XCTAssertEqual(item.subtitle, "Lock current user session")
        XCTAssertEqual(item.category, .quickActions)

        item.action()
        XCTAssertTrue(actionExecuted)
    }

    @MainActor
    func testCommandPaletteCategories() {
        XCTAssertEqual(CommandPaletteCategory.quickActions.rawValue, "Quick Actions")
        XCTAssertEqual(CommandPaletteCategory.windowManagement.rawValue, "Window Management")
        XCTAssertEqual(CommandPaletteCategory.widgets.rawValue, "EdgeDeck Widgets")
        XCTAssertEqual(CommandPaletteCategory.applications.rawValue, "Applications")
        XCTAssertEqual(CommandPaletteCategory.ai.rawValue, "Local AI (Ollama)")
    }
}
