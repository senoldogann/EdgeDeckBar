import Foundation
import XCTest
@testable import EdgeDeck

final class ClipboardHistoryLogicTests: XCTestCase {
    let policy = ClipboardRetentionPolicy(maxEntries: 3, maxBlobBytes: 1024 * 1024)

    func testConsecutiveDuplicateCandidatesDoNotDuplicate() {
        let entry1 = ClipboardEntry(
            id: UUID(),
            timestamp: Date(),
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: false,
            searchableText: "Hello",
            payload: .text("Hello")
        )
        let entry2 = ClipboardEntry(
            id: UUID(),
            timestamp: Date(),
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: false,
            searchableText: "Hello",
            payload: .text("Hello")
        )

        let initial: [ClipboardEntry] = [entry1]
        let merged = mergeClipboardEntry(history: initial, candidate: entry2, policy: policy)

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.id, entry1.id)
    }

    func testPinnedEntriesSurviveTrimmingBeforeUnpinned() {
        let pinnedEntry = ClipboardEntry(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-300),
            sourceBundleIdentifier: "com.apple.Notes",
            isPinned: true,
            searchableText: "Keep Me Pinned",
            payload: .text("Keep Me Pinned")
        )
        let unpinnedEntry1 = ClipboardEntry(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-200),
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: false,
            searchableText: "Temp 1",
            payload: .text("Temp 1")
        )
        let unpinnedEntry2 = ClipboardEntry(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-100),
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: false,
            searchableText: "Temp 2",
            payload: .text("Temp 2")
        )
        let candidate = ClipboardEntry(
            id: UUID(),
            timestamp: Date(),
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: false,
            searchableText: "Newest",
            payload: .text("Newest")
        )

        // Initial history: [unpinned2, unpinned1, pinnedEntry] (count 3, maxEntries = 3)
        // Adding candidate makes 4 items -> oldest unpinned (unpinned1) should be evicted first!
        let initial = [unpinnedEntry2, unpinnedEntry1, pinnedEntry]
        let merged = mergeClipboardEntry(history: initial, candidate: candidate, policy: policy)

        XCTAssertEqual(merged.count, 3)
        XCTAssertEqual(merged.map(\.searchableText), ["Newest", "Temp 2", "Keep Me Pinned"])
        XCTAssertTrue(merged.contains(where: { $0.id == pinnedEntry.id }))
        XCTAssertFalse(merged.contains(where: { $0.id == unpinnedEntry1.id }))
    }

    func testMaxEntryCountIsEnforced() {
        var history: [ClipboardEntry] = []
        for i in 1...5 {
            let entry = ClipboardEntry(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(i)),
                sourceBundleIdentifier: "app",
                isPinned: false,
                searchableText: "Item \(i)",
                payload: .text("Item \(i)")
            )
            history = mergeClipboardEntry(history: history, candidate: entry, policy: policy)
        }

        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history.map(\.searchableText), ["Item 5", "Item 4", "Item 3"])
    }

    func testExcludedBundleIDsAreNotCaptured() {
        let excluded: Set<String> = ["com.1password.1password", "com.apple.keychainaccess"]

        let allowed = shouldCaptureClipboard(
            frontmostBundleIdentifier: "com.apple.Safari",
            excludedBundleIdentifiers: excluded
        )
        XCTAssertTrue(allowed)

        let blocked = shouldCaptureClipboard(
            frontmostBundleIdentifier: "com.1password.1password",
            excludedBundleIdentifiers: excluded
        )
        XCTAssertFalse(blocked)
    }
}
