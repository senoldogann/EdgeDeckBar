import Foundation
import XCTest
@testable import EdgeDeck

final class FlyoutReducerTests: XCTestCase {
    func testOpenSetsVisibleAndActiveID() {
        let initial = FlyoutState(activeItemID: nil, isVisible: false)
        let itemID = UUID()

        let opened = reduceFlyout(state: initial, action: .open(itemID))
        XCTAssertTrue(opened.isVisible)
        XCTAssertEqual(opened.activeItemID, itemID)
    }

    func testSwitchToChangesActiveIDWithoutSecondLogicalFlyout() {
        let id1 = UUID()
        let id2 = UUID()
        let current = FlyoutState(activeItemID: id1, isVisible: true)

        let switched = reduceFlyout(state: current, action: .switchTo(id2))
        XCTAssertTrue(switched.isVisible)
        XCTAssertEqual(switched.activeItemID, id2)
    }

    func testCloseClearsActiveIDAndIsIdempotent() {
        let id = UUID()
        let openState = FlyoutState(activeItemID: id, isVisible: true)

        let closed = reduceFlyout(state: openState, action: .close)
        XCTAssertFalse(closed.isVisible)
        XCTAssertNil(closed.activeItemID)

        let closedAgain = reduceFlyout(state: closed, action: .close)
        XCTAssertFalse(closedAgain.isVisible)
        XCTAssertNil(closedAgain.activeItemID)
    }
}
