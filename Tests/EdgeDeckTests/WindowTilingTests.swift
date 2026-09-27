import CoreGraphics
import XCTest
@testable import EdgeDeck

final class WindowTilingTests: XCTestCase {
    func testMaximizeFillsWorkArea() {
        let screen = CGRect(x: 0.0, y: 0.0, width: 1920.0, height: 1080.0)
        let config = WindowTilingConfiguration(gap: 8.0, edgeMargin: 12.0)
        let frame = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .maximize,
            screenVisibleFrame: screen,
            configuration: config
        )

        XCTAssertEqual(frame.origin.x, 12.0)
        XCTAssertEqual(frame.origin.y, 12.0)
        XCTAssertEqual(frame.width, 1896.0)
        XCTAssertEqual(frame.height, 1056.0)
    }

    func testLeftAndRightHalvesDoNotOverlap() {
        let screen = CGRect(x: 0.0, y: 0.0, width: 1920.0, height: 1080.0)
        let config = WindowTilingConfiguration(gap: 10.0, edgeMargin: 10.0)
        let left = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .leftHalf,
            screenVisibleFrame: screen,
            configuration: config
        )
        let right = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .rightHalf,
            screenVisibleFrame: screen,
            configuration: config
        )

        XCTAssertEqual(left.origin.x, 10.0)
        XCTAssertEqual(left.width, (1900.0 - 10.0) / 2.0)
        XCTAssertEqual(right.origin.x, left.maxX + 10.0)
        XCTAssertEqual(right.maxX, 1910.0)
        XCTAssertFalse(left.intersects(right))
    }

    func testTopAndBottomHalvesDoNotOverlap() {
        let screen = CGRect(x: 0.0, y: 0.0, width: 1920.0, height: 1080.0)
        let config = WindowTilingConfiguration(gap: 10.0, edgeMargin: 10.0)
        let bottom = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .bottomHalf,
            screenVisibleFrame: screen,
            configuration: config
        )
        let top = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .topHalf,
            screenVisibleFrame: screen,
            configuration: config
        )

        XCTAssertEqual(bottom.origin.y, 10.0)
        XCTAssertEqual(top.origin.y, bottom.maxY + 10.0)
        XCTAssertEqual(top.maxY, 1070.0)
        XCTAssertFalse(bottom.intersects(top))
    }

    func testQuarterTiling() {
        let screen = CGRect(x: 0.0, y: 0.0, width: 1920.0, height: 1080.0)
        let config = WindowTilingConfiguration(gap: 8.0, edgeMargin: 10.0)
        let tl = WindowTilingGeometry.calculateCocoaTargetFrame(action: .topLeftQuarter, screenVisibleFrame: screen, configuration: config)
        let tr = WindowTilingGeometry.calculateCocoaTargetFrame(action: .topRightQuarter, screenVisibleFrame: screen, configuration: config)
        let bl = WindowTilingGeometry.calculateCocoaTargetFrame(action: .bottomLeftQuarter, screenVisibleFrame: screen, configuration: config)
        let br = WindowTilingGeometry.calculateCocoaTargetFrame(action: .bottomRightQuarter, screenVisibleFrame: screen, configuration: config)

        XCTAssertFalse(tl.intersects(tr))
        XCTAssertFalse(bl.intersects(br))
        XCTAssertFalse(tl.intersects(bl))
        XCTAssertFalse(tr.intersects(br))
        XCTAssertEqual(tl.origin.x, bl.origin.x)
        XCTAssertEqual(tr.origin.x, br.origin.x)
    }

    func testConvertCocoaToAXFrame() {
        let primaryHeight: CGFloat = 1080.0
        let cocoaTopWindow = CGRect(x: 100.0, y: 580.0, width: 800.0, height: 500.0)
        let axFrame = WindowTilingGeometry.convertCocoaToAXFrame(
            cocoaRect: cocoaTopWindow,
            primaryScreenHeight: primaryHeight
        )

        XCTAssertEqual(axFrame.origin.x, 100.0)
        XCTAssertEqual(axFrame.origin.y, 0.0) // 1080 - (580 + 500) = 0
        XCTAssertEqual(axFrame.width, 800.0)
        XCTAssertEqual(axFrame.height, 500.0)
    }
}
