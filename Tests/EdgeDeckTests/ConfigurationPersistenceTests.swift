import Foundation
import XCTest
@testable import EdgeDeck

final class ConfigurationPersistenceTests: XCTestCase {
    var tempDirectoryURL: URL!
    var configURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("EdgeDeckConfigTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
        configURL = tempDirectoryURL.appendingPathComponent("config.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    func makeDefaultSnapshot() -> ConfigurationSnapshot {
        let placement = DockPlacement(edge: .right, verticalOffsetFraction: 0.5, autoHide: false)
        let preferences = AppPreferences(
            placement: placement,
            materialStyle: .system,
            shortcutBindings: [],
            clipboardRetention: ClipboardRetentionPolicy(maxEntries: 50, maxBlobBytes: 1024),
            clipboardExcludedBundleIdentifiers: [],
            selectedScreenIdentifier: nil,
            reduceMotion: false,
            language: .english,
            dockIconSize: 46.0
        )
        let item = DockItem(
            id: UUID(),
            name: "Test App",
            kind: .application(
                bundleIdentifier: "com.test.app",
                applicationURL: URL(fileURLWithPath: "/Applications/Test.app")
            )
        )
        return ConfigurationSnapshot(
            version: 1,
            preferences: preferences,
            dockItems: [item]
        )
    }

    func testRoundTripPreservesItemsAndPreferences() throws {
        let persistence = ConfigurationPersistence(fileURL: configURL)
        let snapshot = makeDefaultSnapshot()

        try persistence.save(snapshot: snapshot)
        let loadResult = persistence.load(defaultSnapshot: snapshot)

        guard case .loaded(let loaded) = loadResult else {
            XCTFail("Expected .loaded but got \(loadResult)")
            return
        }

        XCTAssertEqual(loaded.version, snapshot.version)
        XCTAssertEqual(loaded.dockItems, snapshot.dockItems)
        XCTAssertEqual(loaded.preferences, snapshot.preferences)
    }

    func testCorruptJSONProducesRecoverableDefaultWithBackup() throws {
        let persistence = ConfigurationPersistence(fileURL: configURL)
        let fallback = makeDefaultSnapshot()

        let corruptContent = "INVALID JSON {{{{".data(using: .utf8)!
        try corruptContent.write(to: configURL)

        let result = persistence.load(defaultSnapshot: fallback)

        guard case .recoveredDefault(let recovered, let backupURL) = result else {
            XCTFail("Expected .recoveredDefault but got \(result)")
            return
        }

        XCTAssertEqual(recovered, fallback)
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
    }

    func testUnknownFutureVersionReturnsMigrationRequired() throws {
        let persistence = ConfigurationPersistence(fileURL: configURL)
        let fallback = makeDefaultSnapshot()

        let futureJSON = """
        {
            "version": 999,
            "preferences": {},
            "dockItems": []
        }
        """.data(using: .utf8)!
        try futureJSON.write(to: configURL)

        let result = persistence.load(defaultSnapshot: fallback)

        guard case .migrationRequired(let foundVersion) = result else {
            XCTFail("Expected .migrationRequired but got \(result)")
            return
        }

        XCTAssertEqual(foundVersion, 999)
    }
}
