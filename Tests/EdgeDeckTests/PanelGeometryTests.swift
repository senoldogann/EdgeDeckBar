import AppKit
import CoreGraphics
import Foundation
import XCTest
@testable import EdgeDeck

final class PanelGeometryTests: XCTestCase {
    let normalScreen = ScreenGeometry(
        identifier: "screen-normal",
        frame: CGRect(x: 0.0, y: 0.0, width: 1920.0, height: 1080.0),
        visibleFrame: CGRect(x: 0.0, y: 0.0, width: 1920.0, height: 1055.0)
    )

    let negativeScreen = ScreenGeometry(
        identifier: "screen-negative",
        frame: CGRect(x: -1920.0, y: 0.0, width: 1920.0, height: 1080.0),
        visibleFrame: CGRect(x: -1920.0, y: 25.0, width: 1920.0, height: 1055.0)
    )

    func testEdgePanelFrameNormalScreen() {
        let size = CGSize(width: 60.0, height: 400.0)
        let rightFrame = edgePanelFrame(
            screen: normalScreen,
            panelSize: size,
            edge: .right,
            edgeInset: 10.0
        )
        XCTAssertEqual(rightFrame.width, 60.0)
        XCTAssertEqual(rightFrame.height, 400.0)
        XCTAssertEqual(rightFrame.maxX, normalScreen.visibleFrame.maxX - 10.0)
        XCTAssertEqual(rightFrame.midY, normalScreen.visibleFrame.midY)

        let leftFrame = edgePanelFrame(
            screen: normalScreen,
            panelSize: size,
            edge: .left,
            edgeInset: 10.0
        )
        XCTAssertEqual(leftFrame.minX, normalScreen.visibleFrame.minX + 10.0)
        XCTAssertEqual(leftFrame.midY, normalScreen.visibleFrame.midY)
    }

    func testEdgePanelFrameNegativeScreen() {
        let size = CGSize(width: 60.0, height: 400.0)
        let rightFrame = edgePanelFrame(
            screen: negativeScreen,
            panelSize: size,
            edge: .right,
            edgeInset: 8.0
        )
        XCTAssertEqual(rightFrame.maxX, negativeScreen.visibleFrame.maxX - 8.0)
        XCTAssertEqual(rightFrame.midY, negativeScreen.visibleFrame.midY)

        let leftFrame = edgePanelFrame(
            screen: negativeScreen,
            panelSize: size,
            edge: .left,
            edgeInset: 8.0
        )
        XCTAssertEqual(leftFrame.minX, negativeScreen.visibleFrame.minX + 8.0)
        XCTAssertEqual(leftFrame.midY, negativeScreen.visibleFrame.midY)
    }

    func testFlyoutPanelFrameClamping() {
        let anchorFrame = CGRect(x: 1850.0, y: 50.0, width: 60.0, height: 50.0)
        let flyoutSize = CGSize(width: 300.0, height: 400.0)

        // Right edge dock -> flyout placed to the left of anchor
        let frame = flyoutPanelFrame(
            anchorFrame: anchorFrame,
            screen: normalScreen,
            edge: .right,
            flyoutSize: flyoutSize,
            gap: 12.0
        )

        XCTAssertEqual(frame.maxX, anchorFrame.minX - 12.0)
        // Must be fully clamped inside visible frame
        XCTAssertGreaterThanOrEqual(frame.minX, normalScreen.visibleFrame.minX)
        XCTAssertLessThanOrEqual(frame.maxX, normalScreen.visibleFrame.maxX)
        XCTAssertGreaterThanOrEqual(frame.minY, normalScreen.visibleFrame.minY)
        XCTAssertLessThanOrEqual(frame.maxY, normalScreen.visibleFrame.maxY)
    }

    func testEdgeActivationFrameOnNegativeScreen() {
        let rightActivation = edgeActivationFrame(
            screen: negativeScreen,
            edge: .right,
            thickness: 4.0
        )
        XCTAssertEqual(rightActivation.width, 4.0)
        XCTAssertEqual(rightActivation.maxX, negativeScreen.visibleFrame.maxX)
        XCTAssertEqual(rightActivation.minY, negativeScreen.visibleFrame.minY)
        XCTAssertEqual(rightActivation.height, negativeScreen.visibleFrame.height)

        let leftActivation = edgeActivationFrame(
            screen: negativeScreen,
            edge: .left,
            thickness: 4.0
        )
        XCTAssertEqual(leftActivation.width, 4.0)
        XCTAssertEqual(leftActivation.minX, negativeScreen.visibleFrame.minX)
        XCTAssertEqual(leftActivation.minY, negativeScreen.visibleFrame.minY)
        XCTAssertEqual(leftActivation.height, negativeScreen.visibleFrame.height)
    }

    func testFlyoutDirectionsAndNegativeScreenClamping() {
        let flyoutSize = CGSize(width: 320.0, height: 450.0)

        // 1. Right-edge dock opens flyout to its left
        let anchorRight = CGRect(x: 1800.0, y: 500.0, width: 60.0, height: 60.0)
        let frameRight = flyoutPanelFrame(
            anchorFrame: anchorRight,
            screen: normalScreen,
            edge: .right,
            flyoutSize: flyoutSize,
            gap: 10.0
        )
        XCTAssertEqual(frameRight.maxX, anchorRight.minX - 10.0)

        // 2. Left-edge dock opens flyout to its right
        let anchorLeft = CGRect(x: 10.0, y: 500.0, width: 60.0, height: 60.0)
        let frameLeft = flyoutPanelFrame(
            anchorFrame: anchorLeft,
            screen: normalScreen,
            edge: .left,
            flyoutSize: flyoutSize,
            gap: 10.0
        )
        XCTAssertEqual(frameLeft.minX, anchorLeft.maxX + 10.0)

        // 3. Clamping keeps full card within negative-origin screen visible frame
        let anchorNegative = CGRect(x: -1910.0, y: 30.0, width: 60.0, height: 60.0)
        let frameNeg = flyoutPanelFrame(
            anchorFrame: anchorNegative,
            screen: negativeScreen,
            edge: .right,
            flyoutSize: flyoutSize,
            gap: 10.0
        )
        XCTAssertGreaterThanOrEqual(frameNeg.minX, negativeScreen.visibleFrame.minX)
        XCTAssertLessThanOrEqual(frameNeg.maxX, negativeScreen.visibleFrame.maxX)
        XCTAssertGreaterThanOrEqual(frameNeg.minY, negativeScreen.visibleFrame.minY)
        XCTAssertLessThanOrEqual(frameNeg.maxY, negativeScreen.visibleFrame.maxY)
    }

    func testEdgePanelFrameTopEdge() {
        let size = CGSize(width: 500.0, height: 68.0)
        let topFrame = edgePanelFrame(
            screen: normalScreen,
            panelSize: size,
            edge: .top,
            edgeInset: 10.0
        )
        XCTAssertEqual(topFrame.width, 500.0)
        XCTAssertEqual(topFrame.height, 68.0)
        XCTAssertEqual(topFrame.midX, normalScreen.visibleFrame.midX)
        XCTAssertEqual(topFrame.maxY, normalScreen.visibleFrame.maxY - 10.0)
    }

    func testFlyoutPanelFrameTopEdge() {
        let anchorFrame = CGRect(x: 700.0, y: 970.0, width: 500.0, height: 68.0)
        let flyoutSize = CGSize(width: 320.0, height: 420.0)
        let frame = flyoutPanelFrame(
            anchorFrame: anchorFrame,
            screen: normalScreen,
            edge: .top,
            flyoutSize: flyoutSize,
            gap: 12.0
        )
        XCTAssertEqual(frame.maxY, anchorFrame.minY - 12.0)
        XCTAssertEqual(frame.midX, anchorFrame.midX)
    }

    func testEdgeActivationFrameTopEdge() {
        let topActivation = edgeActivationFrame(
            screen: normalScreen,
            edge: .top,
            thickness: 6.0
        )
        XCTAssertEqual(topActivation.height, 6.0)
        XCTAssertEqual(topActivation.width, normalScreen.visibleFrame.width)
        XCTAssertEqual(topActivation.maxY, normalScreen.visibleFrame.maxY)
    }
}
