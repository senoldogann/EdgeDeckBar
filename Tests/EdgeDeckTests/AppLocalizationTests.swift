import Foundation
import XCTest
@testable import EdgeDeck

final class AppLocalizationTests: XCTestCase {
    func testLanguageDisplayNames() {
        XCTAssertEqual(AppLanguage.english.displayName, "English")
        XCTAssertEqual(AppLanguage.turkish.displayName, "Türkçe")
    }

    func testEnglishLocalizationStrings() {
        let title = AppLocalization.string(for: .dockShowWindows, language: .english)
        XCTAssertEqual(title, "Show Windows")

        let settings = AppLocalization.string(for: .settingsGeneral, language: .english)
        XCTAssertEqual(settings, "General")

        let quit = AppLocalization.string(for: .dockQuit, language: .english)
        XCTAssertEqual(quit, "Quit EdgeDeck")
    }

    func testTurkishLocalizationStrings() {
        let title = AppLocalization.string(for: .dockShowWindows, language: .turkish)
        XCTAssertEqual(title, "Pencereleri Göster")

        let settings = AppLocalization.string(for: .settingsGeneral, language: .turkish)
        XCTAssertEqual(settings, "Genel")

        let quit = AppLocalization.string(for: .dockQuit, language: .turkish)
        XCTAssertEqual(quit, "EdgeDeck'ten Çık")
    }

    func testAllKeysHaveNonEmptyDefinitions() {
        let testKeys: [LocalizedKey] = [
            .dockShowWindows,
            .dockKeepInDock,
            .dockRemoveFromDock,
            .dockPosition,
            .dockPositionRight,
            .dockPositionLeft,
            .dockPositionTop,
            .dockPositionBottom,
            .dockTheme,
            .dockAutoHide,
            .dockAddAppOrLink,
            .dockSettings,
            .dockQuit,
            .flyoutActiveWindows,
            .flyoutActiveWindow,
            .systemMonitorCPU,
            .systemMonitorMemory,
            .systemMonitorDisk,
            .systemMonitorBattery,
            .systemMonitorThermal,
            .systemMonitorNetwork,
            .weatherHumidity,
            .weatherWind,
            .quickNotesTitle,
            .quickNotesPlaceholder,
            .aiUsageTitle,
            .aiUsageAgentSessions,
            .aiUsageTokens,
            .settingsGeneral,
            .settingsAppearance,
            .settingsShortcuts,
            .settingsClipboard,
            .settingsLanguage
        ]

        for key in testKeys {
            let en = AppLocalization.string(for: key, language: .english)
            let tr = AppLocalization.string(for: key, language: .turkish)
            XCTAssertFalse(en.isEmpty, "Missing english value for \(key.rawValue)")
            XCTAssertFalse(tr.isEmpty, "Missing turkish value for \(key.rawValue)")
        }
    }
}
