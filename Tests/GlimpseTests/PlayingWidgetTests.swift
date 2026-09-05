import XCTest
@testable import Glimpse

final class PlayingWidgetTests: XCTestCase {
    func testPlayingWidgetStartsWithNoMedia() {
        let mediaStore = SystemMediaStore()

        XCTAssertNil(mediaStore.snapshot)
        XCTAssertTrue(mediaStore.spotifyRecentlyPlayed.isEmpty)
    }

    func testStoppingMediaStoreIsSafeBeforeStarting() {
        let mediaStore = SystemMediaStore()

        mediaStore.stop()

        XCTAssertNil(mediaStore.snapshot)
        XCTAssertTrue(mediaStore.spotifyRecentlyPlayed.isEmpty)
    }

    func testSpotifyHistoryTrackPreservesPlaybackMetadata() {
        let track = SpotifyHistoryTrack(
            id: "track-1",
            spotifyURI: "spotify:track:1",
            title: "Song",
            artist: "Artist",
            artwork: nil
        )

        XCTAssertEqual(track.id, "track-1")
        XCTAssertEqual(track.spotifyURI, "spotify:track:1")
        XCTAssertEqual(track.title, "Song")
        XCTAssertEqual(track.artist, "Artist")
        XCTAssertNil(track.artwork)
    }
}
