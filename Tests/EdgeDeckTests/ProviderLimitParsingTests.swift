import Foundation
import XCTest
@testable import EdgeDeck

final class ProviderLimitParsingTests: XCTestCase {
    func testCodexRateLimitLine() throws {
        let line = #"{"timestamp":"2026-09-26T20:17:06.831Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"primary":{"used_percent":37.5,"window_minutes":300,"resets_at":1790471809},"secondary":{"used_percent":12.0,"window_minutes":10080,"resets_at":1791058609}}}}"#
        let snapshot = try XCTUnwrap(parseCodexRateLimitLine(Substring(line), accountID: "acct-1"))
        XCTAssertEqual(snapshot.provider, .codex)
        XCTAssertEqual(snapshot.accountID, "acct-1")
        XCTAssertEqual(snapshot.fiveHour?.usedPercent, 37.5)
        XCTAssertEqual(snapshot.fiveHour?.windowMinutes, 300)
        XCTAssertEqual(snapshot.fiveHour?.resetsAt, Date(timeIntervalSince1970: 1_790_471_809))
        XCTAssertEqual(snapshot.weekly?.windowMinutes, 10_080)
    }

    func testCodexLineWithoutLimitsIsIgnored() {
        let line = #"{"timestamp":"2026-09-26T20:17:06.831Z","type":"event_msg","payload":{"type":"agent_message","message":"hi"}}"#
        XCTAssertNil(parseCodexRateLimitLine(Substring(line), accountID: nil))
    }

    func testCodexSessionAccountID() {
        let line = #"{"timestamp":"2026-09-26T20:17:06.831Z","type":"session_meta","payload":{"id":"s1","creator_account_id":"acct-9"}}"#
        XCTAssertEqual(parseCodexSessionAccountID(firstLine: Substring(line)), "acct-9")
    }

    func testClaudeStatusLineWithEpochAndISOResets() throws {
        let json = #"{"model":{"id":"x"},"rate_limits":{"five_hour":{"used_percentage":42,"resets_at":1790471809},"seven_day":{"used_percentage":8.5,"resets_at":"2026-10-01T12:00:00Z"}}}"#
        let capturedAt = Date(timeIntervalSince1970: 1_790_000_000)
        let snapshot = try XCTUnwrap(try parseClaudeStatusLine(Data(json.utf8), capturedAt: capturedAt))
        XCTAssertEqual(snapshot.fiveHour?.usedPercent, 42.0)
        XCTAssertEqual(snapshot.fiveHour?.resetsAt, Date(timeIntervalSince1970: 1_790_471_809))
        XCTAssertEqual(snapshot.weekly?.usedPercent, 8.5)
        XCTAssertNotNil(snapshot.weekly?.resetsAt)
        XCTAssertEqual(snapshot.capturedAt, capturedAt)
    }

    func testClaudeStatusLineWithoutRateLimitsReturnsNil() throws {
        let json = #"{"model":{"id":"x"},"rate_limits":null}"#
        XCTAssertNil(try parseClaudeStatusLine(Data(json.utf8), capturedAt: Date()))
    }

    func testClaudeTranscriptUsageSumsAllTokenKinds() throws {
        let line = #"{"type":"assistant","timestamp":"2026-09-27T03:39:47.791Z","requestId":"req_1","message":{"id":"msg_1","usage":{"input_tokens":2,"output_tokens":280,"cache_creation_input_tokens":100,"cache_read_input_tokens":1000}}}"#
        let usage = try XCTUnwrap(parseClaudeTranscriptUsage(line: Substring(line)))
        XCTAssertEqual(usage.tokens, 1_382)
        XCTAssertEqual(usage.dedupeKey, "msg_1|req_1")
    }

    func testT3ClaudeUsageCacheIsScopedToEmail() throws {
        let json = #"{"auth":{"status":"authenticated","email":"Me@Example.com"},"usageLimits":{"checkedAt":"2026-09-27T12:39:21.082Z","windows":[{"id":"five_hour","kind":"session","windowDurationMins":300,"usedPercent":12,"resetsAt":"2026-09-27T16:49:59.643Z"},{"id":"seven_day","kind":"weekly","windowDurationMins":10080,"usedPercent":9,"resetsAt":"2026-10-02T20:59:59.643Z"}]}}"#
        let scoped = try XCTUnwrap(try parseT3UsageCache(Data(json.utf8), provider: .claude, source: "test"))
        XCTAssertEqual(scoped.email, "Me@Example.com")
        XCTAssertEqual(scoped.snapshot.provider, .claude)
        XCTAssertEqual(scoped.snapshot.fiveHour?.usedPercent, 12.0)
        XCTAssertEqual(scoped.snapshot.weekly?.windowMinutes, 10_080)
        XCTAssertNotNil(scoped.snapshot.fiveHour?.resetsAt)
    }

    func testT3ClaudeUsageCacheIgnoresSignedOutAccounts() throws {
        let json = #"{"auth":{"status":"unauthenticated","email":"me@example.com"},"usageLimits":{"checkedAt":"2026-09-27T12:39:21.082Z","windows":[]}}"#
        XCTAssertNil(try parseT3UsageCache(Data(json.utf8), provider: .claude, source: "test"))
    }

    func testEffectiveUsedPercentDropsAfterReset() {
        let now = Date()
        let window = UsageWindow(usedPercent: 91.0, windowMinutes: 300, resetsAt: now.addingTimeInterval(-1))
        XCTAssertEqual(effectiveUsedPercent(window: window, now: now), 0.0)
    }

    func testClaudePlanDisplayName() {
        XCTAssertEqual(claudePlanDisplayName(tier: "default_claude_max_20x"), "Max 20x")
        XCTAssertEqual(claudePlanDisplayName(tier: "default_claude_pro"), "Pro")
    }
}
