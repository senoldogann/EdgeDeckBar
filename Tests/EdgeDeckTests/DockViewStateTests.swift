import CoreGraphics
import Foundation
import XCTest
@testable import EdgeDeck

final class DockViewStateTests: XCTestCase {
    func testMakeDockViewState() {
        let item1 = DockItem(
            id: UUID(),
            name: "App 1",
            kind: .application(
                bundleIdentifier: "com.example.app1",
                applicationURL: URL(fileURLWithPath: "/Applications/App1.app")
            )
        )
        let item2 = DockItem(
            id: UUID(),
            name: "Clipboard",
            kind: .widget(widgetIdentifier: "clipboard")
        )
        let placement = DockPlacement(
            edge: .right,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let state = AppState(
            dockItems: [item1, item2],
            selectedItemID: item2.id,
            placement: placement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        let geom1 = DockItemGeometry(
            id: item1.id,
            logicalFrame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: 48.0)
        )
        let geom2 = DockItemGeometry(
            id: item2.id,
            logicalFrame: CGRect(x: 0.0, y: 48.0, width: 48.0, height: 48.0)
        )
        let config = DockMagnificationConfiguration(
            maxScale: 1.4,
            influenceRadius: 60.0,
            maxLift: 6.0
        )

        let viewState = makeDockViewState(
            state: state,
            pointer: CGPoint(x: 24.0, y: 48.0 + 24.0), // at item2's center
            itemFrames: [geom1, geom2],
            configuration: config,
            weatherState: nil,
            aiUsageState: nil,
            systemMetrics: nil,
            nowPlayingState: nil
        )

        XCTAssertEqual(viewState.edge, DockEdge.right)
        XCTAssertTrue(viewState.isRevealed)
        XCTAssertEqual(viewState.selectedItemID, item2.id)
        XCTAssertEqual(viewState.items.count, 2)
        XCTAssertEqual(viewState.items[0].id, item1.id)
        XCTAssertFalse(viewState.items[0].isSelected)
        XCTAssertEqual(viewState.items[1].id, item2.id)
        XCTAssertTrue(viewState.items[1].isSelected)

        // Item 2 is at center of pointer -> scale is maxScale (1.4)
        XCTAssertEqual(viewState.items[1].transform.scale, 1.4, accuracy: 0.001)
        XCTAssertEqual(viewState.items[1].transform.logicalFrame, geom2.logicalFrame)
        XCTAssertEqual(viewState.items[0].transform.logicalFrame, geom1.logicalFrame)
    }

    func testMakeDockViewStateWithLiveWeatherAndAIState() {
        let weatherItem = DockItem(
            id: UUID(),
            name: "Weather",
            kind: .widget(widgetIdentifier: "weather")
        )
        let aiItem = DockItem(
            id: UUID(),
            name: "AI Agents",
            kind: .widget(widgetIdentifier: "ai_usage")
        )
        let musicItem = DockItem(
            id: UUID(),
            name: "Now Playing",
            kind: .widget(widgetIdentifier: "now_playing")
        )

        let state = AppState(
            dockItems: [weatherItem, aiItem, musicItem],
            selectedItemID: nil,
            placement: DockPlacement(edge: .left, verticalOffsetFraction: 0.5, autoHide: false),
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        let weather = WeatherState(
            cityName: "Helsinki",
            temperatureCelsius: 16.4,
            conditionText: "Partly Cloudy",
            symbolName: "cloud.sun.fill",
            highCelsius: 18.0,
            lowCelsius: 12.0,
            hourly: [],
            lastUpdated: Date()
        )

        let ai = AIUsageState(
            agentSessions: [
                AIAgentSession(
                    id: "claude",
                    agentType: .claude,
                    isRunning: true,
                    pid: 1234,
                    activeDirectory: "/Users/test",
                    modelName: "claude-opus-5-5",
                    lastTaskPrompt: "Testing live agent",
                    lastActivityTime: Date(),
                    costOrTokenSummary: "Active"
                )
            ],
            limitCards: [],
            dailyUsage: [],
            ollamaModels: [],
            recentActivities: [],
            isPrivacyPreserving: true,
            lastUpdated: Date()
        )

        let viewState = makeDockViewState(
            state: state,
            pointer: nil,
            itemFrames: [],
            configuration: DockMagnificationConfiguration(maxScale: 1.4, influenceRadius: 60.0, maxLift: 6.0),
            weatherState: weather,
            aiUsageState: ai,
            systemMetrics: nil,
            nowPlayingState: NowPlayingState(
                trackTitle: "Midnight City",
                artist: "M83",
                album: "Hurry Up",
                isPlaying: true,
                playbackPosition: 45.0,
                duration: 240.0,
                playerSource: "Spotify"
            )
        )

        let weatherViewItem = viewState.items.first(where: { $0.id == weatherItem.id })
        XCTAssertEqual(weatherViewItem?.badgeText, "16°")

        let aiViewItem = viewState.items.first(where: { $0.id == aiItem.id })
        XCTAssertEqual(aiViewItem?.badgeText, "LIVE")
        XCTAssertTrue(aiViewItem?.isRunning == true)

        let musicViewItem = viewState.items.first(where: { $0.id == musicItem.id })
        XCTAssertEqual(musicViewItem?.badgeText, "PLAY")
        XCTAssertTrue(musicViewItem?.isRunning == true)
    }
}
