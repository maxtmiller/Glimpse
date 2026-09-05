import XCTest
@testable import Glimpse

final class MeetingsWidgetTests: XCTestCase {
    func testMeetingControlsStartWithSafeNoDataDefaults() {
        let controls = MeetingControlsStore()

        XCTAssertFalse(controls.microphoneMuted)
        XCTAssertFalse(controls.outputMuted)
        XCTAssertEqual(controls.inputName, "Default microphone")
        XCTAssertEqual(controls.outputName, "Default speakers")
        XCTAssertEqual(controls.outputVolume, 0)
        XCTAssertEqual(controls.microphoneLevel, 0)
        XCTAssertTrue(controls.inputDevices.isEmpty)
        XCTAssertTrue(controls.outputDevices.isEmpty)
    }

    func testAudioDevicesUseStableIdentityAndValueEquality() {
        let first = MeetingControlsStore.AudioDevice(id: 42, name: "Built-in Microphone")
        let same = MeetingControlsStore.AudioDevice(id: 42, name: "Built-in Microphone")
        let different = MeetingControlsStore.AudioDevice(id: 43, name: "USB Microphone")

        XCTAssertEqual(first.id, 42)
        XCTAssertEqual(first, same)
        XCTAssertNotEqual(first, different)
    }

    func testStoppingMeetingControlsIsSafeBeforeStarting() {
        let controls = MeetingControlsStore()

        controls.stop()

        XCTAssertEqual(controls.microphoneLevel, 0)
    }
}
