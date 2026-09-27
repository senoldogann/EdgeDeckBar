import Foundation
import XCTest
@testable import EdgeDeck

final class QuickNotesTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
        super.tearDown()
    }

    @MainActor
    func testSaveAndLoadNotes() {
        let service = QuickNotesService(baseURL: tempDirectory)
        XCTAssertEqual(service.loadNotes(), "")

        let testContent = "Meeting with design team at 3 PM.\nReview PR #42."
        service.saveNotes(testContent)

        let loaded = service.loadNotes()
        XCTAssertEqual(loaded, testContent)
    }

    @MainActor
    func testOverwriteNotes() {
        let service = QuickNotesService(baseURL: tempDirectory)
        service.saveNotes("Initial Draft")
        XCTAssertEqual(service.loadNotes(), "Initial Draft")

        service.saveNotes("Updated Final Note")
        XCTAssertEqual(service.loadNotes(), "Updated Final Note")
    }
}
