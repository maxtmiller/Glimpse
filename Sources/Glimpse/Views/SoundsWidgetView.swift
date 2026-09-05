import AppKit
import SwiftUI

struct GlimpseSoundsWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: GlimpsePage

    @StateObject private var mediaStore = SystemMediaStore()
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false
    @State private var hoveredControl: String?
    @State private var hoveredSpotifyTrackID: String?
    @State private var spotifyListMode: SpotifyListMode = .recentlyPlayed
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
        GlimpseWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                if isExpanded {
                    HStack(spacing: 10) {
                        GlimpseSummaryHeader(
                            icon: "waveform",
                            title: media?.isPlaying == true ? "Playing" : "Paused",
                            subtitle: "Computer audio",
                            accent: .purple,
                            showsSubtitle: true
                        )

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
                } else {
                    collapsedMediaHeader
                }
            },
            trailing: {
                if isExpanded {
                    HStack(spacing: 10) {
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

                        GlimpseSummaryBadge(text: media?.appName ?? "No audio")
                        if let media {
                            GlimpseSummaryBadge(text: media.isPlaying ? "Playing" : "Paused")
                        }
                    }
                    .padding(.trailing, 4)
                } else {
                    collapsedNowPlaying
                }
            },
            expanded: {
                VStack(spacing: 9) {
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

                    HStack(spacing: 18) {
                        soundControlButton(symbol: "backward.fill", label: "Previous", action: mediaStore.skipPrevious)
                        soundControlButton(
                            symbol: media?.isPlaying == true ? "pause.fill" : "play.fill",
                            label: media?.isPlaying == true ? "Pause" : "Play",
                            emphasized: true,
                            action: mediaStore.togglePlayback
                        )
                        soundControlButton(symbol: "forward.fill", label: "Next", action: mediaStore.skipNext)
                    }

                    if media?.appName == "Spotify" {
                        spotifyHistoryStrip
                            .offset(y: -10)
                    }
                }
                .padding(.top, 5)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        )
        .onAppear { mediaStore.start() }
    }

    private var spotifyHistoryStrip: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    spotifyListMode = spotifyListMode == .next ? .recentlyPlayed : .next
                }
            } label: {
                Image(systemName: spotifyListMode == .next ? "clock.arrow.circlepath" : "text.line.first.and.arrowtriangle.forward")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 25, height: 25)
                    .background(Color.white.opacity(0.09), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(InteractiveButtonStyle())
            .help(spotifyListMode == .next ? "Show recently played" : "Show next")

            VStack(alignment: .leading, spacing: 1) {
                Text(spotifyListMode.title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                    .textCase(.uppercase)

                if spotifyListMode == .next {
                    Text("Spotify queue is available in the app")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                } else if mediaStore.spotifyRecentlyPlayed.isEmpty {
                    Text("Play a song to build your list")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(mediaStore.spotifyRecentlyPlayed) { track in
                                Button {
                                    mediaStore.playSpotifyTrack(track)
                                } label: {
                                    spotifyTrackCard(track, isHovered: hoveredSpotifyTrackID == track.id)
                                }
                                .buttonStyle(InteractiveButtonStyle())
                                .onHover { hovering in
                                    hoveredSpotifyTrackID = hovering ? track.id : nil
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                    .frame(height: 42)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 1)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func spotifyTrackCard(_ track: SpotifyHistoryTrack, isHovered: Bool) -> some View {
        HStack(spacing: 6) {
            Group {
                if let artwork = track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green.opacity(0.28))
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.46))
                    .lineLimit(1)
            }
            .frame(width: 82, alignment: .leading)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.green.opacity(0.16) : Color.white.opacity(0.065))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isHovered ? Color.green.opacity(0.72) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.035 : 1)
        .shadow(color: isHovered ? Color.green.opacity(0.24) : .clear, radius: 6)
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .help("\(track.title) · \(track.artist)")
    }

    private var collapsedNowPlaying: some View {
        HStack(spacing: 12) {
            CollapsedProgressRing(progress: progressRatio, tint: progressTint)
            CollapsedSourceIcon(
                appName: media?.appName,
                bundleIdentifier: media?.appBundleIdentifier,
                tint: progressTint
            )
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }

    private var collapsedMediaHeader: some View {
        HStack(spacing: 10) {
            if media != nil {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let pulse = 1 + (sin(context.date.timeIntervalSinceReferenceDate * 3.2) + 1) * 0.025

                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(progressTint.opacity(media?.isPlaying == true ? 0.26 : 0.12))
                            .frame(width: 30, height: 30)
                            .scaleEffect(pulse)
                            .opacity(media?.isPlaying == true ? 0.9 : 0.55)

                        ZStack {
                            if let image = media?.artwork {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                LinearGradient(
                                    colors: [progressTint.opacity(0.88), .purple.opacity(0.62)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                Image(systemName: "waveform")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                    }
                    .frame(width: 32, height: 32)
                }

                CollapsedSoundWave(isPlaying: media?.isPlaying == true, tint: progressTint)
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))

                Text("Sounds")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .help(media.map { "\($0.title) · \($0.artist.isEmpty ? $0.album : $0.artist)" } ?? "No audio")
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
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(Color.white.opacity(0.78), lineWidth: 1))
                        .shadow(color: progressTint.opacity(0.72), radius: 5)
                        .offset(x: min(max(fillWidth - 3.5, 0), proxy.size.width - 7))
                }
            }
            .animation(.easeOut(duration: 0.25), value: progressRatio)
        }
        .frame(height: 4)
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
            .frame(width: emphasized ? 34 : 28, height: emphasized ? 34 : 28)
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

private enum SpotifyListMode {
    case next
    case recentlyPlayed

    var title: String {
        switch self {
        case .next: return "Next"
        case .recentlyPlayed: return "Recently played"
        }
    }
}

private struct CollapsedSoundWave: View {
    let isPlaying: Bool
    let tint: Color

    @State private var isAnimating = false

    private let barHeights: [CGFloat] = [8, 15, 11, 18, 10]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                Capsule(style: .continuous)
                    .fill(tint.opacity(isPlaying ? 0.92 : 0.48))
                    .frame(width: 3, height: height)
                    .scaleEffect(y: isPlaying && isAnimating ? 1 : 0.35, anchor: .center)
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: 0.42)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.09)
                            : .easeOut(duration: 0.16),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 30, height: 22)
        .onAppear {
            isAnimating = isPlaying
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                isAnimating = false
                DispatchQueue.main.async {
                    isAnimating = true
                }
            } else {
                isAnimating = false
            }
        }
        .accessibilityLabel(isPlaying ? "Audio playing" : "Audio paused")
    }
}

private struct CollapsedProgressRing: View {
    let progress: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 21, height: 21)
        .animation(.easeOut(duration: 0.25), value: progress)
        .accessibilityLabel("Track progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

private struct CollapsedSourceIcon: View {
    let appName: String?
    let bundleIdentifier: String?
    let tint: Color

    var body: some View {
        Group {
            if let icon = applicationIcon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: appName == "Spotify" ? "waveform" : "music.note")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.9))
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityLabel(appName ?? "Audio source")
    }

    private var applicationIcon: NSImage? {
        let applicationBundleIdentifier: String?
        if let bundleIdentifier {
            if bundleIdentifier.hasPrefix("com.google.Chrome") {
                applicationBundleIdentifier = "com.google.Chrome"
            } else if bundleIdentifier.hasPrefix("com.apple.Safari") {
                applicationBundleIdentifier = "com.apple.Safari"
            } else if bundleIdentifier.hasPrefix("org.mozilla.firefox") {
                applicationBundleIdentifier = "org.mozilla.firefox"
            } else {
                applicationBundleIdentifier = bundleIdentifier
            }
        } else {
            applicationBundleIdentifier = nil
        }

        if let applicationBundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: applicationBundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }

        guard let appName else { return nil }

        let paths: [String]
        switch appName {
        case "Spotify":
            paths = ["/Applications/Spotify.app", "\(NSHomeDirectory())/Applications/Spotify.app"]
        case "Apple Music":
            paths = ["/System/Applications/Music.app", "/Applications/Music.app"]
        case "Google Chrome":
            paths = ["/Applications/Google Chrome.app", "\(NSHomeDirectory())/Applications/Google Chrome.app"]
        case "Safari":
            paths = ["/Applications/Safari.app", "/System/Applications/Safari.app"]
        case "Firefox":
            paths = ["/Applications/Firefox.app", "\(NSHomeDirectory())/Applications/Firefox.app"]
        default:
            paths = []
        }

        guard let path = paths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
