import Foundation
import XCTest
@testable import EdgeDeck

final class AppReducerTests: XCTestCase {
    func testAddItem() {
        let placement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let initial = AppState(
            dockItems: [],
            selectedItemID: nil,
            placement: placement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )
        let item = DockItem(
            id: UUID(),
            name: "Safari",
            kind: .application(
                bundleIdentifier: "com.apple.Safari",
                applicationURL: URL(fileURLWithPath: "/Applications/Safari.app")
            )
        )

        let result = reduce(state: initial, action: .addItem(item))

        XCTAssertEqual(result.dockItems, [item])
    }

    func testMoveItem() {
        let placement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let first = DockItem(
            id: UUID(),
            name: "App 1",
            kind: .widget(widgetIdentifier: "clipboard")
        )
        let second = DockItem(
            id: UUID(),
            name: "App 2",
            kind: .link(url: URL(string: "https://example.com")!)
        )
        let withTwoItems = AppState(
            dockItems: [first, second],
            selectedItemID: nil,
            placement: placement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        let result = reduce(
            state: withTwoItems,
            action: .moveItem(sourceID: first.id, destinationID: second.id)
        )

        XCTAssertEqual(result.dockItems.map(\.id), [second.id, first.id])
    }

    func testRemoveItemClearsSelectionIfSelected() {
        let placement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let selectedID = UUID()
        let selectedItem = DockItem(
            id: selectedID,
            name: "Selected App",
            kind: .widget(widgetIdentifier: "clipboard")
        )
        let selected = AppState(
            dockItems: [selectedItem],
            selectedItemID: selectedID,
            placement: placement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        let result = reduce(state: selected, action: .removeItem(id: selectedID))

        XCTAssertEqual(result.selectedItemID, nil)
        XCTAssertTrue(result.dockItems.isEmpty)
    }

    func testSelectPlacementAndRevealActions() {
        let placement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let newPlacement = DockPlacement(
            edge: .left,
            verticalOffsetFraction: 0.25,
            autoHide: true
        )
        let targetID = UUID()
        let state = AppState(
            dockItems: [],
            selectedItemID: nil,
            placement: placement,
            isDockRevealed: false,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        let revealed = reduce(state: state, action: .revealDock)
        XCTAssertTrue(revealed.isDockRevealed)

        let hidden = reduce(state: revealed, action: .hideDock)
        XCTAssertFalse(hidden.isDockRevealed)

        let placed = reduce(state: hidden, action: .updatePlacement(newPlacement))
        XCTAssertEqual(placed.placement, newPlacement)

        let selected = reduce(state: placed, action: .selectItem(id: targetID))
        XCTAssertEqual(selected.selectedItemID, targetID)
    }

    func testMoveItemEdgeCases() {
        let placement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let item1 = DockItem(
            id: UUID(),
            name: "Item 1",
            kind: .widget(widgetIdentifier: "w1")
        )
        let item2 = DockItem(
            id: UUID(),
            name: "Item 2",
            kind: .widget(widgetIdentifier: "w2")
        )
        let state = AppState(
            dockItems: [item1, item2],
            selectedItemID: nil,
            placement: placement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        // Same ID is no-op
        let same = reduce(state: state, action: .moveItem(sourceID: item1.id, destinationID: item1.id))
        XCTAssertEqual(same.dockItems.map(\.id), [item1.id, item2.id])

        // Unknown source leaves order unchanged
        let unknownSource = reduce(state: state, action: .moveItem(sourceID: UUID(), destinationID: item2.id))
        XCTAssertEqual(unknownSource.dockItems.map(\.id), [item1.id, item2.id])

        // Unknown destination leaves order unchanged
        let unknownDest = reduce(state: state, action: .moveItem(sourceID: item1.id, destinationID: UUID()))
        XCTAssertEqual(unknownDest.dockItems.map(\.id), [item1.id, item2.id])
    }
}
