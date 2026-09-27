import AppKit
import Foundation
import XCTest
@testable import EdgeDeck

final class PanelBehaviorTests: XCTestCase {
    func testEdgePanelCollectionBehavior() {
        let behavior = edgePanelCollectionBehavior()
        XCTAssertTrue(behavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(behavior.contains(.fullScreenAuxiliary))
    }
}
