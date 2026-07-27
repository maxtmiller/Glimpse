import SwiftUI

struct NotchSoundsWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: NotchPage

    @StateObject private var mediaStore = SystemMediaStore()
    @State private var isHomeButtonHovered = false
    @State private var hoveredControl: String?
    @State private var playbackClock = Date()

    private let playbackTimer = Timer.publish(
        every: 1.0 / 30.0,
        on: .main,
        in: .common
    ).autoconnect()

    private var media: SystemMediaSnapshot? { mediaStore.snapshot }
    private var livePosition: Double {
        guard let media else { return 0 }
        guard media.isPlaying else { return media.position }

        return min(
            media.duration,
            max(0, media.position + playbackClock.timeIntervalSince(media.updatedAt))
        )
    }

    private var progressRatio: CGFloat {
        guard let media, media.duration > 0 else { return 0 }
        return min(1, max(0, livePosition / media.duration))
    }

    private var progressTint: Color {
        Color(nsColor: media?.appColor ?? .systemPurple)
    }

    var body: some View {
        playerContent
            .onReceive(playbackTimer) { now in
                playbackClock = now
            }
    }

    private var playerContent: some View {
        NotchWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    NotchSummaryHeader(
                        icon: "waveform",
                        title: "Now Playing",
                        subtitle: "Computer audio",
                        accent: .purple,
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)
                        NotchNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(NotchMotion.pageTransitionAnimation) {
                                selectedPage = .home
                            }
                        }
                        .offset(x: -4)
                    }
                }
            },
            trailing: {
                HStack(spacing: 5) {
                    NotchSummaryBadge(text: media?.appName ?? "No audio")
                    if isExpanded, let media {
                        NotchSummaryBadge(text: media.isPlaying ? "Playing" : "Paused")
                    }
                }
                .padding(.trailing, 4)
            },
            expanded: {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        artwork

                        VStack(alignment: .leading, spacing: 4) {
                            Text(media?.title ?? "Nothing playing")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(media.map { $0.artist.isEmpty ? $0.album : $0.artist } ?? "Start audio in Music or Spotify")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)

                            if let media {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(Color(nsColor: media.appColor))
                                        .frame(width: 5, height: 5)
                                    Text("Playing from \(media.appName)")
                                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.46))
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }

                    VStack(spacing: 5) {
                        progressBar

                        HStack {
                            Text(formatTime(livePosition))
                            Spacer()
                            Text(formatTime(media?.duration ?? 0))
                        }
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                        .monospacedDigit()
                    }

                    HStack(spacing: 22) {
                        soundControlButton(symbol: "backward.fill", label: "Previous", action: mediaStore.skipPrevious)
                        soundControlButton(
                            symbol: media?.isPlaying == true ? "pause.fill" : "play.fill",
                            label: media?.isPlaying == true ? "Pause" : "Play",
                            emphasized: true,
                            action: mediaStore.togglePlayback
                        )
                        soundControlButton(symbol: "forward.fill", label: "Next", action: mediaStore.skipNext)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        )
        .onAppear { mediaStore.start() }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let fillWidth = proxy.size.width * progressRatio

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(progressTint.opacity(0.18))
                    .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [progressTint.opacity(0.95), progressTint.opacity(0.62)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)

                if progressRatio > 0 {
                    Circle()
                        .fill(progressTint)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.white.opacity(0.78), lineWidth: 1))
                        .shadow(color: progressTint.opacity(0.72), radius: 5)
                        .offset(x: min(max(fillWidth - 4.5, 0), proxy.size.width - 9))
                }
            }
            .animation(.easeOut(duration: 0.25), value: progressRatio)
        }
        .frame(height: 9)
        .accessibilityLabel("Track progress")
        .accessibilityValue("\(formatTime(livePosition)) of \(formatTime(media?.duration ?? 0))")
    }

    private var artwork: some View {
        ZStack {
            if let image = media?.artwork {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(nsColor: media?.appColor ?? .systemPurple).opacity(0.9), .purple.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: media == nil ? "music.note" : "waveform")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
        .shadow(color: .purple.opacity(0.22), radius: 9, y: 3)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let wholeSeconds = max(0, Int(seconds))
        return String(format: "%d:%02d", wholeSeconds / 60, wholeSeconds % 60)
    }

    private func soundControlButton(
        symbol: String,
        label: String,
        emphasized: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let isHovered = hoveredControl == label

        return Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        isHovered
                            ? progressTint.opacity(emphasized ? 0.42 : 0.24)
                            : (emphasized ? Color.white.opacity(0.16) : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isHovered ? progressTint.opacity(0.75) : Color.white.opacity(emphasized ? 0.14 : 0),
                                lineWidth: 1
                            )
                    )

                Image(systemName: symbol)
                    .font(.system(size: emphasized ? 14 : 11, weight: .bold))
                    .foregroundStyle(.white.opacity(isHovered || emphasized ? 1 : 0.72))
            }
            .frame(width: emphasized ? 38 : 32, height: emphasized ? 38 : 32)
            .scaleEffect(isHovered ? 1.08 : 1)
            .shadow(color: isHovered ? progressTint.opacity(0.44) : .clear, radius: 9)
        }
        .buttonStyle(InteractiveButtonStyle())
        .onHover { hovering in
            hoveredControl = hovering ? label : nil
        }
        .help(label)
    }
}
