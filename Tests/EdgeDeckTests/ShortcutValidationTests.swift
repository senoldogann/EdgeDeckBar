import Foundation
import XCTest
@testable import EdgeDeck

final class ShortcutValidationTests: XCTestCase {
    func testEmptyBindingsProduceNoConflicts() {
        let conflicts = shortcutConflicts(bindings: [])
        XCTAssertTrue(conflicts.isEmpty)
    }

    func testDistinctChordsProduceNoConflicts() {
        let chord1 = ShortcutChord(carbonKeyCode: 0x31, carbonModifiers: 0x0100) // Space + cmd
        let chord2 = ShortcutChord(carbonKeyCode: 0x35, carbonModifiers: 0x0100) // Esc + cmd

        let binding1 = ShortcutBinding(
            id: UUID(),
            chord: chord1,
            action: .toggleDock
        )
        let binding2 = ShortcutBinding(
            id: UUID(),
            chord: chord2,
            action: .openAddPanel
        )

        let conflicts = shortcutConflicts(bindings: [binding1, binding2])
        XCTAssertTrue(conflicts.isEmpty)
    }

    func testDuplicateChordsProduceDeterministicConflict() {
        let chord = ShortcutChord(carbonKeyCode: 0x31, carbonModifiers: 0x0100)
        let id1 = UUID()
        let id2 = UUID()

        let binding1 = ShortcutBinding(
            id: id1,
            chord: chord,
            action: .toggleDock
        )
        let binding2 = ShortcutBinding(
            id: id2,
            chord: chord,
            action: .openClipboard
        )

        let conflicts = shortcutConflicts(bindings: [binding1, binding2])
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts[0].bindingIDs, Set([id1, id2]))
        XCTAssertEqual(conflicts[0].chord, chord)
    }

    func testTileWindowShortcutEncodingAndDecoding() throws {
        let binding = ShortcutBinding(
            id: UUID(),
            chord: ShortcutChord(carbonKeyCode: 0x7B, carbonModifiers: 0x1800),
            action: .tileWindow(.leftHalf)
        )

        let data = try JSONEncoder().encode(binding)
        let decoded = try JSONDecoder().decode(ShortcutBinding.self, from: data)

        XCTAssertEqual(binding.id, decoded.id)
        XCTAssertEqual(binding.chord, decoded.chord)
        XCTAssertEqual(binding.action, decoded.action)
    }
}
