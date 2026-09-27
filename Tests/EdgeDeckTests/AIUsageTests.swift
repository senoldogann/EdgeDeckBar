import Foundation
import XCTest
@testable import EdgeDeck

final class AIUsageTests: XCTestCase {
    @MainActor
    private func makeService(initialState: AIUsageState) -> (AIUsageService, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("edgedeck-ai-\(UUID().uuidString)")
        let bridge = ClaudeStatusLineBridge(supportDirectory: root, homeDirectory: root)
        let service = AIUsageService(
            initialState: initialState,
            accountStore: AIAccountStore(registryURL: root.appendingPathComponent("ai_accounts.json"), homeDirectory: root),
            usageScanner: ProviderUsageScanner(homeDirectory: root, claudeCaptureURL: bridge.captureURL),
            claudeBridge: bridge
        )
        return (service, root)
    }

    func testDefaultSampleStructure() {
        let sample = AIUsageState.defaultSample()
        XCTAssertTrue(sample.isPrivacyPreserving)
        XCTAssertEqual(sample.recentActivities.count, 3)
        XCTAssertTrue(sample.limitCards.isEmpty)
        XCTAssertNil(sample.lowestFiveHourRemainingPercent(now: Date()))
    }

    @MainActor
    func testAIUsageServiceRecordActivity() {
        let (service, root) = makeService(initialState: AIUsageState.defaultSample())
        defer { try? FileManager.default.removeItem(at: root) }
        let initialActivityCount = service.currentState.recentActivities.count

        service.recordActivity(
            title: "Unit Test Task",
            modelName: "Llama-3.2-3B-Instruct",
            tokenCount: 500,
            status: .completed
        )

        let updated = service.currentState
        XCTAssertEqual(updated.recentActivities.count, initialActivityCount + 1)
        XCTAssertEqual(updated.recentActivities.first?.title, "Unit Test Task")
        XCTAssertEqual(updated.recentActivities.first?.tokenCount, 500)
        XCTAssertEqual(updated.recentActivities.first?.status, .completed)
    }

    func testLowestFiveHourRemainingIgnoresExpiredWindows() {
        let now = Date()
        let expired = ProviderLimitSnapshot(
            provider: .codex,
            accountID: "a",
            fiveHour: UsageWindow(usedPercent: 97.0, windowMinutes: 300, resetsAt: now.addingTimeInterval(-60)),
            weekly: nil,
            capturedAt: now
        )
        let live = ProviderLimitSnapshot(
            provider: .claude,
            accountID: nil,
            fiveHour: UsageWindow(usedPercent: 42.0, windowMinutes: 300, resetsAt: now.addingTimeInterval(3_600)),
            weekly: nil,
            capturedAt: now
        )
        let cards = [expired, live].map { snapshot in
            ProviderLimitCard(
                provider: snapshot.provider,
                activeAccount: nil,
                savedAccounts: [],
                limits: snapshot,
                savedAccountLimits: [:],
                isLimitSourceConnected: true,
                isProviderRunning: false,
                loginIssue: nil,
                accountsNeedingLogin: []
            )
        }
        let state = AIUsageState(
            agentSessions: [],
            limitCards: cards,
            dailyUsage: [],
            ollamaModels: [],
            recentActivities: [],
            isPrivacyPreserving: true,
            lastUpdated: now
        )
        XCTAssertEqual(state.lowestFiveHourRemainingPercent(now: now), 58.0)
    }

    func testAgentSessionsInDefaultSample() {
        let sample = AIUsageState.defaultSample()
        XCTAssertEqual(sample.agentSessions.count, 4)
        XCTAssertTrue(sample.agentSessions.contains(where: { $0.agentType == .claude }))
        XCTAssertTrue(sample.agentSessions.contains(where: { $0.agentType == .codex }))
        XCTAssertTrue(sample.agentSessions.contains(where: { $0.agentType == .opencode }))
        XCTAssertTrue(sample.agentSessions.contains(where: { $0.agentType == .ollama }))
        XCTAssertTrue(sample.hasRunningAgent)
    }

    @MainActor
    func testAIUsageServiceRefreshLive() async {
        let (service, root) = makeService(initialState: .empty)
        defer { try? FileManager.default.removeItem(at: root) }

        await service.refresh()

        let refreshed = service.currentState
        XCTAssertEqual(refreshed.agentSessions.count, 4)
        XCTAssertNotNil(refreshed.agentSessions.first(where: { $0.agentType == .claude }))
        XCTAssertEqual(refreshed.limitCards.map(\.provider), [.claude, .codex])
        // Boş ev dizininde oturum açılmış hesap yoktur
        XCTAssertTrue(refreshed.limitCards.allSatisfy { $0.activeAccount == nil })
    }
}
