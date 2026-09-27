import XCTest
@testable import EdgeDeck

final class NowPlayingTests: XCTestCase {
    func testIdleStateCreation() {
        let state = NowPlayingState.idle()
        XCTAssertEqual(state.trackTitle, "No Track Playing")
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.playerSource, "Ready")
        XCTAssertEqual(state.playbackPosition, 0.0)
        XCTAssertEqual(state.duration, 0.0)
    }

    func testCustomStateProperties() {
        let state = NowPlayingState(
            trackTitle: "Midnight City",
            artist: "M83",
            album: "Hurry Up, We're Dreaming",
            isPlaying: true,
            playbackPosition: 120.0,
            duration: 240.0,
            playerSource: "Spotify"
        )
        XCTAssertEqual(state.trackTitle, "Midnight City")
        XCTAssertEqual(state.artist, "M83")
        XCTAssertEqual(state.album, "Hurry Up, We're Dreaming")
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.playbackPosition, 120.0)
        XCTAssertEqual(state.duration, 240.0)
        XCTAssertEqual(state.playerSource, "Spotify")
        XCTAssertEqual(state.progressFraction, 0.5, accuracy: 0.001)
        XCTAssertEqual(state.formattedPosition, "02:00")
        XCTAssertEqual(state.formattedDuration, "04:00")
    }
}
