import CoreGraphics
import Foundation
import XCTest
@testable import EdgeDeck

final class MagnificationGeometryTests: XCTestCase {
    func testMagnificationBehavior() {
        let config = DockMagnificationConfiguration(
            maxScale: 1.42,
            influenceRadius: 80.0,
            maxLift: 8.0
        )

        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        let item1 = DockItemGeometry(
            id: id1,
            logicalFrame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: 48.0)
        )
        let item2 = DockItemGeometry(
            id: id2,
            logicalFrame: CGRect(x: 0.0, y: 48.0, width: 48.0, height: 48.0)
        )
        let item3 = DockItemGeometry(
            id: id3,
            logicalFrame: CGRect(x: 0.0, y: 96.0, width: 48.0, height: 48.0)
        )
        let items = [item1, item2, item3]

        // 1. Pointer at item1's center (24, 24)
        let centerPointer = CGPoint(x: 24.0, y: 24.0)
        let transformsAtCenter = magnificationTransforms(
            items: items,
            pointer: centerPointer,
            configuration: config
        )

        guard let transform1 = transformsAtCenter[id1],
              let transform2 = transformsAtCenter[id2] else {
            XCTFail("Transforms missing for items")
            return
        }

        XCTAssertEqual(transform1.scale, 1.42, accuracy: 0.001)
        XCTAssertGreaterThan(transform2.scale, 1.0)
        XCTAssertLessThan(transform2.scale, 1.42)

        // 2. Pointer nil returns scale 1.0 and zero translation for every item
        let nilTransforms = magnificationTransforms(
            items: items,
            pointer: nil,
            configuration: config
        )
        for item in items {
            guard let t = nilTransforms[item.id] else {
                XCTFail("Missing transform for item \(item.id)")
                continue
            }
            XCTAssertEqual(t.scale, 1.0)
            XCTAssertEqual(t.translationY, 0.0)
            XCTAssertEqual(t.logicalFrame, item.logicalFrame)
        }

        // 3. Every returned logicalFrame equals its input frame exactly
        for item in items {
            XCTAssertEqual(transformsAtCenter[item.id]?.logicalFrame, item.logicalFrame)
        }

        // 4. Two pointer positions one point apart near a boundary differ in scale by less than 0.08
        let posA = CGPoint(x: 24.0, y: 103.0)
        let posB = CGPoint(x: 24.0, y: 104.0)
        let transA = magnificationTransforms(
            items: items,
            pointer: posA,
            configuration: config
        )
        let transB = magnificationTransforms(
            items: items,
            pointer: posB,
            configuration: config
        )
        let scaleDiff = abs((transA[id1]?.scale ?? 0.0) - (transB[id1]?.scale ?? 0.0))
        XCTAssertLessThan(scaleDiff, 0.08)

        // 5. Animation policy
        XCTAssertEqual(
            animationPolicy(reduceMotion: false),
            .spring(response: 0.18, dampingFraction: 0.82)
        )
        XCTAssertEqual(
            animationPolicy(reduceMotion: true),
            .reducedMotion(duration: 0.12)
        )
    }
}
