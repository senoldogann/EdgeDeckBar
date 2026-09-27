import Foundation
import XCTest
@testable import EdgeDeck

final class ClipboardPersistenceTests: XCTestCase {
    var tempDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("EdgeDeckClipboardTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    func testRoundTripMetadata() throws {
        let persistence = ClipboardPersistence(baseURL: tempDirectoryURL)
        let entry1 = ClipboardEntry(
            id: UUID(),
            timestamp: Date(),
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: true,
            searchableText: "https://apple.com",
            payload: .url(URL(string: "https://apple.com")!)
        )
        let entry2 = ClipboardEntry(
            id: UUID(),
            timestamp: Date(),
            sourceBundleIdentifier: "com.apple.Notes",
            isPinned: false,
            searchableText: "Note text",
            payload: .text("Note text")
        )

        try persistence.saveHistory([entry1, entry2])
        let loaded = try persistence.loadHistory()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, entry1.id)
        XCTAssertEqual(loaded[0].payload, entry1.payload)
        XCTAssertEqual(loaded[1].id, entry2.id)
        XCTAssertEqual(loaded[1].payload, entry2.payload)
    }

    func testImageBlobStoredSeparatelyAndSafelyDegradesWhenMissing() throws {
        let persistence = ClipboardPersistence(baseURL: tempDirectoryURL)
        let fakeImageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        let blobPath = "test_image.png"

        try persistence.saveBlob(data: fakeImageData, relativePath: blobPath)
        let loadedData = persistence.loadBlob(relativePath: blobPath)
        XCTAssertEqual(loadedData, fakeImageData)

        // Missing blob degrades safely to nil
        let missingData = persistence.loadBlob(relativePath: "nonexistent.png")
        XCTAssertNil(missingData)
    }

    func testCleanupUnreferencedBlobs() throws {
        let persistence = ClipboardPersistence(baseURL: tempDirectoryURL)
        let blob1 = "keep.png"
        let blob2 = "orphan.png"

        try persistence.saveBlob(data: Data([0x01]), relativePath: blob1)
        try persistence.saveBlob(data: Data([0x02]), relativePath: blob2)

        try persistence.cleanupUnreferencedBlobs(referencedPaths: [blob1])

        XCTAssertNotNil(persistence.loadBlob(relativePath: blob1))
        XCTAssertNil(persistence.loadBlob(relativePath: blob2))
    }
}
