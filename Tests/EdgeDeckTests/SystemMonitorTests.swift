import Foundation
import XCTest
@testable import EdgeDeck

final class SystemMonitorTests: XCTestCase {
    @MainActor
    func testSampleSystemMetricsProducesRealisticValues() {
        let service = SystemMonitorService()
        let metrics = service.sampleMetrics()

        // CPU
        XCTAssertGreaterThanOrEqual(metrics.cpu.usagePercent, 0.0)
        XCTAssertLessThanOrEqual(metrics.cpu.usagePercent, 100.0)

        // Memory
        XCTAssertGreaterThan(metrics.memory.totalBytes, 0)
        XCTAssertGreaterThan(metrics.memory.usedBytes, 0)
        XCTAssertLessThanOrEqual(metrics.memory.usedBytes, metrics.memory.totalBytes)
        XCTAssertGreaterThanOrEqual(metrics.memory.usagePercent, 0.0)
        XCTAssertLessThanOrEqual(metrics.memory.usagePercent, 100.0)

        // Disk
        XCTAssertGreaterThan(metrics.disk.totalBytes, 0)
        XCTAssertGreaterThanOrEqual(metrics.disk.usedBytes, 0)
        XCTAssertLessThanOrEqual(metrics.disk.usedBytes, metrics.disk.totalBytes)
        XCTAssertGreaterThanOrEqual(metrics.disk.usagePercent, 0.0)
        XCTAssertLessThanOrEqual(metrics.disk.usagePercent, 100.0)

        // Thermal
        XCTAssertFalse(metrics.thermal.stateName.isEmpty)

        // Network
        XCTAssertFalse(metrics.network.formattedDownloadSpeed.isEmpty)
        XCTAssertFalse(metrics.network.formattedUploadSpeed.isEmpty)
    }

    func testSystemMetricsFormatting() {
        let cpu = SystemCPUMetrics(usagePercent: 24.5, userPercent: 18.0, systemPercent: 6.5)
        let memory = SystemMemoryMetrics(
            usedBytes: 8 * 1024 * 1024 * 1024,
            totalBytes: 16 * 1024 * 1024 * 1024,
            usagePercent: 50.0,
            freeBytes: 8 * 1024 * 1024 * 1024
        )
        let disk = SystemDiskMetrics(
            usedBytes: 250 * 1024 * 1024 * 1024,
            totalBytes: 500 * 1024 * 1024 * 1024,
            usagePercent: 50.0,
            freeBytes: 250 * 1024 * 1024 * 1024
        )
        let battery = SystemBatteryMetrics(levelPercent: 88, isCharging: true, isPluggedIn: true)
        let thermal = SystemThermalMetrics(stateName: "Nominal", isThrottling: false)
        let network = SystemNetworkMetrics(bytesInPerSecond: 1024 * 1024 * 5, bytesOutPerSecond: 1024 * 50)

        let metrics = SystemMetrics(
            cpu: cpu,
            memory: memory,
            disk: disk,
            battery: battery,
            thermal: thermal,
            network: network
        )

        XCTAssertEqual(metrics.cpu.usagePercent, 24.5)
        XCTAssertEqual(metrics.memory.usagePercent, 50.0)
        XCTAssertEqual(metrics.disk.usagePercent, 50.0)
        XCTAssertEqual(metrics.battery?.levelPercent, 88)
        XCTAssertEqual(metrics.thermal.stateName, "Nominal")
        XCTAssertEqual(metrics.network.formattedDownloadSpeed, "5.0 MB/s")
        XCTAssertEqual(metrics.network.formattedUploadSpeed, "50.0 KB/s")
    }
}
