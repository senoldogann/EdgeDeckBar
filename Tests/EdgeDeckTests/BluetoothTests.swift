import Foundation
import XCTest
@testable import EdgeDeck

final class BluetoothTests: XCTestCase {
    func testDefaultSampleHasValidDevices() {
        let sample = BluetoothState.defaultSample()
        XCTAssertTrue(sample.isBluetoothEnabled)
        XCTAssertEqual(sample.devices.count, 3)

        let airpods = sample.devices.first(where: { $0.id == "sample_airpods" })
        XCTAssertNotNil(airpods)
        XCTAssertEqual(airpods?.name, "AirPods Pro")
        XCTAssertEqual(airpods?.isConnected, true)
        XCTAssertEqual(airpods?.batteryPercentage, 88)
        XCTAssertEqual(airpods?.deviceType, .headphones)

        let mouse = sample.devices.first(where: { $0.id == "sample_mouse" })
        XCTAssertNotNil(mouse)
        XCTAssertEqual(mouse?.deviceType, .mouse)
        XCTAssertEqual(mouse?.batteryPercentage, 74)

        let keyboard = sample.devices.first(where: { $0.id == "sample_keyboard" })
        XCTAssertNotNil(keyboard)
        XCTAssertEqual(keyboard?.deviceType, .keyboard)
        XCTAssertEqual(keyboard?.isConnected, false)
        XCTAssertNil(keyboard?.batteryPercentage)
    }

    func testBluetoothDeviceTypeIconSystemNames() {
        XCTAssertEqual(BluetoothDeviceType.headphones.iconSystemName, "headphones")
        XCTAssertEqual(BluetoothDeviceType.mouse.iconSystemName, "magicmouse.fill")
        XCTAssertEqual(BluetoothDeviceType.keyboard.iconSystemName, "keyboard.fill")
        XCTAssertEqual(BluetoothDeviceType.trackpad.iconSystemName, "hand.draw.fill")
        XCTAssertEqual(BluetoothDeviceType.phone.iconSystemName, "iphone")
        XCTAssertEqual(BluetoothDeviceType.watch.iconSystemName, "applewatch")
        XCTAssertEqual(BluetoothDeviceType.other.iconSystemName, "dot.radiowaves.left.and.right")
    }

    @MainActor
    func testBluetoothServiceLifecycle() {
        let initial = BluetoothState.defaultSample()
        let service = BluetoothService(initialState: initial)

        XCTAssertEqual(service.currentState.devices.count, 3)
        let fetched = service.fetchCurrentState()
        XCTAssertFalse(fetched.devices.isEmpty)
    }
}
