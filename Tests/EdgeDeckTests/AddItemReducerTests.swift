import Foundation
import XCTest
@testable import EdgeDeck

final class AddItemReducerTests: XCTestCase {
    func testClampingWhenResultsShrink() {
        let initial = AddItemState(
            category: .apps,
            searchQuery: "",
            selectedIndex: 4,
            isVisible: true
        )

        // When result count shrinks to 3, selectedIndex should clamp to 2
        let updated = reduceAddItem(
            state: initial,
            action: .setSearchQuery("note", resultCount: 3)
        )
        XCTAssertEqual(updated.selectedIndex, 2)
    }

    func testZeroResultsClearsSelection() {
        let initial = AddItemState(
            category: .apps,
            searchQuery: "x",
            selectedIndex: 2,
            isVisible: true
        )

        let updated = reduceAddItem(
            state: initial,
            action: .setSearchQuery("xyz", resultCount: 0)
        )
        XCTAssertNil(updated.selectedIndex)
    }

    func testArrowNavigation() {
        let initial = AddItemState(
            category: .apps,
            searchQuery: "",
            selectedIndex: 0,
            isVisible: true
        )

        let next = reduceAddItem(
            state: initial,
            action: .selectNext(resultCount: 3)
        )
        XCTAssertEqual(next.selectedIndex, 1)

        let next2 = reduceAddItem(
            state: next,
            action: .selectNext(resultCount: 3)
        )
        XCTAssertEqual(next2.selectedIndex, 2)

        // Clamped at end
        let next3 = reduceAddItem(
            state: next2,
            action: .selectNext(resultCount: 3)
        )
        XCTAssertEqual(next3.selectedIndex, 2)

        let prev = reduceAddItem(
            state: next3,
            action: .selectPrevious(resultCount: 3)
        )
        XCTAssertEqual(prev.selectedIndex, 1)
    }
}
