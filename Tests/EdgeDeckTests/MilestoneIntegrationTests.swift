import Foundation
import XCTest
@testable import EdgeDeck

final class MilestoneIntegrationTests: XCTestCase {
    func testEndToEndValueFlow() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EdgeDeckIntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        let configPersistence = ConfigurationPersistence(fileURL: configFile)

        let initialPlacement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let initialPreferences = AppPreferences(
            placement: initialPlacement,
            materialStyle: .system,
            shortcutBindings: [],
            clipboardRetention: ClipboardRetentionPolicy(maxEntries: 50, maxBlobBytes: 1024 * 1024),
            clipboardExcludedBundleIdentifiers: ["com.1password.1password"],
            selectedScreenIdentifier: nil,
            reduceMotion: false,
            language: .english,
            dockIconSize: 46.0
        )
        var state = AppState(
            dockItems: [],
            selectedItemID: nil,
            placement: initialPlacement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        // 1. Add app, link, and clipboard items
        let appItem = DockItem(
            id: UUID(),
            name: "Calculator",
            kind: .application(
                bundleIdentifier: "com.apple.calculator",
                applicationURL: URL(fileURLWithPath: "/System/Applications/Calculator.app")
            )
        )
        let linkItem = DockItem(
            id: UUID(),
            name: "Example",
            kind: .link(url: URL(string: "https://example.com")!)
        )
        let clipboardItem = DockItem(
            id: UUID(),
            name: "Clipboard",
            kind: .widget(widgetIdentifier: "clipboard")
        )

        state = reduce(state: state, action: .addItem(appItem))
        state = reduce(state: state, action: .addItem(linkItem))
        state = reduce(state: state, action: .addItem(clipboardItem))
        XCTAssertEqual(state.dockItems.map(\.id), [appItem.id, linkItem.id, clipboardItem.id])

        // 2. Reorder items
        state = reduce(state: state, action: .moveItem(sourceID: clipboardItem.id, destinationID: appItem.id))
        XCTAssertEqual(state.dockItems.map(\.id), [clipboardItem.id, appItem.id, linkItem.id])

        // 3. Select item
        state = reduce(state: state, action: .selectItem(id: clipboardItem.id))
        XCTAssertEqual(state.selectedItemID, clipboardItem.id)

        // 4. Update placement
        let newPlacement = DockPlacement(edge: .left, verticalOffsetFraction: 0.3, autoHide: true)
        state = reduce(state: state, action: .updatePlacement(newPlacement))
        XCTAssertEqual(state.placement, newPlacement)

        // 5. Open and close flyout
        state = reduce(state: state, action: .flyout(.open(clipboardItem.id)))
        XCTAssertTrue(state.flyout.isVisible)
        XCTAssertEqual(state.flyout.activeItemID, clipboardItem.id)

        state = reduce(state: state, action: .flyout(.close))
        XCTAssertFalse(state.flyout.isVisible)
        XCTAssertNil(state.flyout.activeItemID)

        // 6. Persist snapshot and reload
        let updatedPreferences = AppPreferences(
            placement: state.placement,
            materialStyle: .translucent,
            shortcutBindings: [],
            clipboardRetention: initialPreferences.clipboardRetention,
            clipboardExcludedBundleIdentifiers: initialPreferences.clipboardExcludedBundleIdentifiers,
            selectedScreenIdentifier: "display-1",
            reduceMotion: true,
            language: .turkish,
            dockIconSize: 54.0
        )
        let snapshot = ConfigurationSnapshot(
            version: 1,
            preferences: updatedPreferences,
            dockItems: state.dockItems
        )
        try configPersistence.save(snapshot: snapshot)

        let loadResult = configPersistence.load(defaultSnapshot: snapshot)
        guard case .loaded(let loaded) = loadResult else {
            XCTFail("Failed to reload configuration: \(loadResult)")
            return
        }

        XCTAssertEqual(loaded.dockItems, state.dockItems)
        XCTAssertEqual(loaded.preferences.placement, state.placement)
        XCTAssertEqual(loaded.preferences.materialStyle, .translucent)
        XCTAssertEqual(loaded.preferences.reduceMotion, true)
    }
}
