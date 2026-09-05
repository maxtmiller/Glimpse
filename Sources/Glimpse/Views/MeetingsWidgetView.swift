import SwiftUI
import CoreAudio

struct GlimpseMeetingsWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: GlimpsePage

    @StateObject private var controls = MeetingControlsStore()
    @StateObject private var mediaStore = SystemMediaStore()
    @State private var hoveredControl: String?
    @State private var hoveredDeviceMenu: String?
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false

    var body: some View {
        GlimpseWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    GlimpseSummaryHeader(
                        icon: "video.fill",
                        title: "Meetings",
                        subtitle: "Mic, camera & audio",
                        accent: .red,
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)
                        GlimpseNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
                                selectedPage = .home
                            }
                        }
                        .offset(x: -4)
                    }
                }
            },
            trailing: {
                HStack(spacing: isExpanded ? 10 : 5) {
                    if isExpanded {
                        GlimpseNavigationButton(
                            systemName: "gearshape.fill",
                            title: "Settings",
                            isHovered: $isSettingsButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
                                selectedPage = .settings
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    }

                    GlimpseSummaryBadge(text: statusText)
                }
                .padding(.trailing, 4)
            },
            expanded: {
                VStack(alignment: .leading, spacing: 11) {
                    GlimpseHeader(
                        title: "Meeting controls",
                        subtitle: "Mic, camera & audio at a glance"
                    )

                    HStack(spacing: 8) {
                        microphoneMeter
                        soundOutputMeter
                    }

                    HStack(spacing: 8) {
                        VStack(spacing: 8) {
                            controlRow(
                                id: "microphone",
                                icon: controls.microphoneMuted ? "mic.slash.fill" : "mic.fill",
                                title: controls.microphoneMuted ? "Mic muted" : "Mic on",
                                detail: controls.inputName,
                                isOn: controls.microphoneMuted,
                                tint: .orange,
                                action: controls.toggleMicrophone
                            )
                            deviceMenu(
                                title: "Input",
                                icon: "mic.fill",
                                current: controls.inputName,
                                devices: controls.inputDevices,
                                selectedID: controls.selectedInputID,
                                select: controls.selectInput
                            )
                        }

                        VStack(spacing: 8) {
                            controlRow(
                                id: "output",
                                icon: controls.outputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                title: controls.outputMuted ? "Deafened" : "Audio on",
                                detail: controls.outputName,
                                isOn: controls.outputMuted,
                                tint: .cyan,
                                action: controls.toggleOutput
                            )
                            deviceMenu(
                                title: "Output",
                                icon: "speaker.wave.2.fill",
                                current: controls.outputName,
                                devices: controls.outputDevices,
                                selectedID: controls.selectedOutputID,
                                select: controls.selectOutput
                            )
                        }
                    }
                }
                .padding(.horizontal, 13)
                .padding(.top, 9)
                .padding(.bottom, 13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        )
        .onAppear {
            controls.start()
            mediaStore.start()
        }
        .onDisappear {
            controls.stop()
            mediaStore.stop()
        }
    }

    private var statusText: String {
        if controls.microphoneMuted && controls.outputMuted { return "Muted + deafened" }
        if controls.microphoneMuted { return "Mic muted" }
        if controls.outputMuted { return "Deafened" }
        return "Ready"
    }

    private var soundOutputMeter: some View {
        let isPlaying = mediaStore.snapshot?.isPlaying == true
        let level = isPlaying && !controls.outputMuted ? controls.outputVolume : 0

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("SOUND OUTPUT")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.42))
                Spacer()
                Text(isPlaying ? "PLAYING" : "IDLE")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(isPlaying ? .green : .white.opacity(0.4))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.09))
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(level))
                }
            }
            .frame(height: 6)
        }
    }

    private var microphoneMeter: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("MIC ACTIVITY")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.42))
                Spacer()
                Text(controls.microphoneMuted ? "MUTED" : "LIVE")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(controls.microphoneMuted ? .orange : .green)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.09))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(controls.microphoneLevel))
                }
            }
            .frame(height: 6)
        }
    }

    private func deviceMenu(
        title: String,
        icon: String,
        current: String,
        devices: [MeetingControlsStore.AudioDevice],
        selectedID: AudioDeviceID?,
        select: @escaping (MeetingControlsStore.AudioDevice) -> Void
    ) -> some View {
        let isHovered = hoveredDeviceMenu == title

        return Menu {
            ForEach(devices) { device in
                Button {
                    select(device)
                } label: {
                    HStack {
                        Text(device.name)
                        Spacer()
                        if selectedID == device.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title.uppercased())
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                    Text(current)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.13 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: 1)
        )
        .onHover { hoveredDeviceMenu = $0 ? title : nil }
        .help("Switch (title.lowercased()) device")
    }

    private func controlRow(
        id: String,
        icon: String,
        title: String,
        detail: String,
        isOn: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        let isHovered = hoveredControl == id

        return Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isOn ? tint : .white.opacity(0.78))
                    .frame(width: 28, height: 28)
                    .background((isOn ? tint : Color.white).opacity(isOn ? 0.18 : 0.08), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(detail)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(isOn ? "OFF" : "ON")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(isOn ? tint : .white.opacity(0.45))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background((isOn ? tint : Color.white).opacity(isOn ? 0.16 : 0.07), in: Capsule())
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(Color.white.opacity(isHovered ? 0.13 : 0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(isOn ? tint.opacity(0.44) : Color.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveButtonStyle())
        .onHover { hoveredControl = $0 ? id : nil }
        .help("Toggle (title.lowercased())")
    }
}
