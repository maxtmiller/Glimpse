import Foundation
import AppKit
import AVFoundation
import AVFAudio
import Combine
import CoreAudio

/// Controls the default input and output devices used by every application.
///
/// macOS does not expose a public API that can revoke another application's
/// camera capture session. The widget can report camera activity and open
/// the privacy settings, while the microphone and speaker controls below
/// are applied to Core Audio devices.
final class MeetingControlsStore: ObservableObject {
    struct AudioDevice: Identifiable, Equatable {
        let id: AudioDeviceID
        let name: String
    }

    @Published private(set) var microphoneMuted = false
    @Published private(set) var outputMuted = false
    @Published private(set) var inputName = "Default microphone"
    @Published private(set) var outputName = "Default speakers"
    @Published private(set) var outputVolume: Float = 0
    @Published private(set) var inputDevices: [AudioDevice] = []
    @Published private(set) var outputDevices: [AudioDevice] = []
    @Published private(set) var selectedInputID: AudioDeviceID?
    @Published private(set) var selectedOutputID: AudioDeviceID?
    @Published private(set) var cameraInUse = false
    @Published private(set) var microphoneLevel: Float = 0

    private var refreshTimer: Timer?
    private let audioEngine = AVAudioEngine()
    private var isMeasuringMicrophone = false

    func start() {
        guard refreshTimer == nil else {
            refresh()
            return
        }

        refresh()
        startMicrophoneMeter()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isMeasuringMicrophone = false
    }

    func toggleMicrophone() {
        setMute(!microphoneMuted, scope: kAudioObjectPropertyScopeInput)
    }

    func toggleOutput() {
        setMute(!outputMuted, scope: kAudioObjectPropertyScopeOutput)
    }

    func selectInput(_ device: AudioDevice) {
        setDefaultDevice(device.id, selector: kAudioHardwarePropertyDefaultInputDevice)
    }

    func selectOutput(_ device: AudioDevice) {
        setDefaultDevice(device.id, selector: kAudioHardwarePropertyDefaultOutputDevice)
    }

    private func refresh() {
        let input = defaultDevice(scope: kAudioHardwarePropertyDefaultInputDevice)
        let output = defaultDevice(scope: kAudioHardwarePropertyDefaultOutputDevice)

        inputDevices = devices(scope: kAudioDevicePropertyScopeInput)
        outputDevices = devices(scope: kAudioDevicePropertyScopeOutput)
        selectedInputID = input
        selectedOutputID = output

        microphoneMuted = input.map { isMuted($0, scope: kAudioObjectPropertyScopeInput) } ?? false
        outputMuted = output.map { isMuted($0, scope: kAudioObjectPropertyScopeOutput) } ?? false
        inputName = input.flatMap(deviceName) ?? "No microphone"
        outputName = output.flatMap(deviceName) ?? "No speakers"
        outputVolume = output.flatMap(volume) ?? 0
        cameraInUse = discoveredVideoDevices().contains { $0.isInUseByAnotherApplication }
    }

    private func discoveredVideoDevices() -> [AVCaptureDevice] {
        var deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .externalUnknown
        ]

        if #available(macOS 14.0, *) {
            deviceTypes.append(.continuityCamera)
        }

        return AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    private func startMicrophoneMeter() {
        guard !isMeasuringMicrophone else { return }
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.installMicrophoneMeter()
            }
        }
    }

    private func installMicrophoneMeter() {
        guard !isMeasuringMicrophone else { return }
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { return }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
            var sum: Float = 0
            for index in 0..<Int(buffer.frameLength) {
                sum += channelData[index] * channelData[index]
            }
            let rms = sqrt(sum / Float(buffer.frameLength))
            let level = min(1, max(0, (20 * log10(max(rms, 0.00001)) + 60) / 60))
            DispatchQueue.main.async {
                self?.microphoneLevel = level
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isMeasuringMicrophone = true
        } catch {
            inputNode.removeTap(onBus: 0)
        }
    }

    private func setMute(_ muted: Bool, scope: AudioObjectPropertyScope) {
        let selector = scope == kAudioObjectPropertyScopeInput
            ? kAudioHardwarePropertyDefaultInputDevice
            : kAudioHardwarePropertyDefaultOutputDevice
        guard let device = defaultDevice(scope: selector) else { return }

        var value: UInt32 = muted ? 1 : 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            device,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &value
        )

        // Some devices do not expose a mute property. Falling back to zero
        // input volume still makes the microphone inaudible on those devices.
        if status != noErr, scope == kAudioObjectPropertyScopeInput {
            setInputVolume(0, device: device)
        }
        refresh()
    }

    private func setInputVolume(_ volume: Float, device: AudioDeviceID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var value = volume
        _ = AudioObjectSetPropertyData(
            device,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &value
        )
    }

    private func isMuted(_ device: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr else {
            return false
        }
        return value != 0
    }

    private func volume(_ device: AudioDeviceID) -> Float? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr else {
            return nil
        }
        return min(1, max(0, value))
    }

    private func defaultDevice(scope: AudioObjectPropertySelector) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: scope,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &device
        ) == noErr, device != 0 else {
            return nil
        }
        return device
    }

    private func devices(scope: AudioObjectPropertyScope) -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else {
            return []
        }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.stride
        guard count > 0 else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: count)
        let status = ids.withUnsafeMutableBytes { buffer in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                0,
                nil,
                &size,
                buffer.baseAddress!
            )
        }
        guard status == noErr else {
            return []
        }

        return ids.compactMap { id in
            guard hasStreams(id, scope: scope), let name = deviceName(id) else { return nil }
            return AudioDevice(id: id, name: name)
        }
    }

    private func hasStreams(_ device: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: scope,
            mElement: kAudioObjectPropertyElementWildcard
        )
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr && size > 0
    }

    private func setDefaultDevice(_ device: AudioDeviceID, selector: AudioObjectPropertySelector) {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value = device
        _ = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &value
        )
        refresh()
    }

    private func deviceName(_ device: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name) == noErr else {
            return nil
        }
        guard let name else { return nil }
        return name.takeUnretainedValue() as String
    }
}
