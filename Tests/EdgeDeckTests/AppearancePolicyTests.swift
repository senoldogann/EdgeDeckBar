import Foundation
import XCTest
@testable import EdgeDeck

final class AppearancePolicyTests: XCTestCase {
    func testReducedMotionRemovesSpringOvershoot() {
        let normal = animationPolicy(reduceMotion: false)
        XCTAssertEqual(normal, .spring(response: 0.18, dampingFraction: 0.82))

        let reduced = animationPolicy(reduceMotion: true)
        XCTAssertEqual(reduced, .reducedMotion(duration: 0.12))
    }

    func testCustomRGBAClamping() {
        let clamped = clampCustomRGBA(r: -0.5, g: 1.5, b: 0.5, a: 2.0)
        XCTAssertEqual(clamped.0, 0.0)
        XCTAssertEqual(clamped.1, 1.0)
        XCTAssertEqual(clamped.2, 0.5)
        XCTAssertEqual(clamped.3, 1.0)
    }

    func testDockMaterialStyleEquality() {
        XCTAssertEqual(DockMaterialStyle.system, DockMaterialStyle.system)
        XCTAssertEqual(DockMaterialStyle.translucent, DockMaterialStyle.translucent)
        XCTAssertEqual(
            DockMaterialStyle.customRGBA(0.1, 0.2, 0.3, 0.8),
            DockMaterialStyle.customRGBA(0.1, 0.2, 0.3, 0.8)
        )
        XCTAssertNotEqual(
            DockMaterialStyle.system,
            DockMaterialStyle.translucent
        )
        XCTAssertEqual(DockMaterialStyle.crystalClear, DockMaterialStyle.crystalClear)
        XCTAssertEqual(DockMaterialStyle.obsidianDark, DockMaterialStyle.obsidianDark)
        XCTAssertEqual(DockMaterialStyle.auroraGlow, DockMaterialStyle.auroraGlow)
        XCTAssertEqual(DockMaterialStyle.cyberpunkGlass, DockMaterialStyle.cyberpunkGlass)
        XCTAssertEqual(DockMaterialStyle.titaniumFrost, DockMaterialStyle.titaniumFrost)

        XCTAssertEqual(DockMaterialStyle.crystalClear.displayName, "Crystal Clear")
        XCTAssertEqual(DockMaterialStyle.obsidianDark.displayName, "Obsidian Dark")
        XCTAssertEqual(DockMaterialStyle.auroraGlow.displayName, "Aurora Borealis")
        XCTAssertEqual(DockMaterialStyle.cyberpunkGlass.displayName, "Cyberpunk Neon")
        XCTAssertEqual(DockMaterialStyle.titaniumFrost.displayName, "Titanium Frost")
    }
}
