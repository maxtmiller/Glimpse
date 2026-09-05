import XCTest
@testable import Glimpse

final class GlimpsePageTests: XCTestCase {
    func testWidgetPagesExcludeNonWidgetPages() {
        XCTAssertFalse(GlimpsePage.widgetPages.contains(.home))
        XCTAssertFalse(GlimpsePage.widgetPages.contains(.settings))
        XCTAssertTrue(GlimpsePage.widgetPages.contains(.weather))
        XCTAssertTrue(GlimpsePage.widgetPages.contains(.markets))
    }

    func testMeetingsSubtitleDoesNotMentionCamera() {
        XCTAssertFalse(GlimpsePage.meetings.subtitle.localizedCaseInsensitiveContains("camera"))
        XCTAssertEqual(GlimpsePage.meetings.subtitle, "Mic & audio")
    }
}
