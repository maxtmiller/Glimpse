import AppKit
import Combine
import CoreAudio

struct SystemMediaSnapshot {
    let title: String
    let artist: String
    let album: String
    let appName: String
    let appBundleIdentifier: String?
    let appColor: NSColor
    let artwork: NSImage?
    let isPlaying: Bool
    let position: Double
    let duration: Double
    let updatedAt: Date
    let spotifyURI: String?
}

struct SpotifyHistoryTrack: Identifiable {
    let id: String
    let spotifyURI: String
    let title: String
    let artist: String
    let artwork: NSImage?
}

final class SystemMediaStore: ObservableObject {
    @Published private(set) var snapshot: SystemMediaSnapshot?
    @Published private(set) var spotifyRecentlyPlayed: [SpotifyHistoryTrack] = []

    private var pollTimer: Timer?
    private var activePlayer: MediaPlayer?
    private var isPolling = false

    func start() {
        guard pollTimer == nil else {
            refresh()
            return
        }

        refresh()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func togglePlayback() {
        guard let activePlayer else { return }
        runCommand(activePlayer, command: """
        if player state is playing then
            pause
        else
            play
        end if
        """)
        refreshAfterCommand()
    }

    func skipNext() {
        guard let activePlayer else { return }
        runCommand(activePlayer, command: "next track")
        refreshAfterCommand()
    }

    func skipPrevious() {
        guard let activePlayer else { return }
        runCommand(activePlayer, command: "previous track")
        refreshAfterCommand()
    }

    func playSpotifyTrack(_ track: SpotifyHistoryTrack) {
        let escapedURI = track.spotifyURI.replacingOccurrences(of: "\\\"", with: "\\\\\"")
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                play track "\(escapedURI)"
            end tell
        end if
        """
        var error: NSDictionary?
        _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error {
            print("Glimpse Spotify track command failed: \(error)")
        }
        refreshAfterCommand()
    }

    private func refreshAfterCommand() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.refresh()
        }
    }

    private func refresh() {
        guard !isPolling else { return }
        isPolling = true

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let results = MediaPlayer.allCases.compactMap { player in
                self?.readSnapshot(for: player)
            }
            let playing = results.first(where: { $0.snapshot.isPlaying })
            let browserResult = results.first(where: { $0.player.isBrowser })
            let result = playing ?? browserResult ?? results.first

            DispatchQueue.main.async {
                guard let self else { return }
                self.activePlayer = result?.player
                self.snapshot = result?.snapshot
                if result?.player == .spotify, let snapshot = result?.snapshot {
                    self.recordSpotifyTrack(snapshot)
                }
                self.isPolling = false
            }
        }
    }

    private func recordSpotifyTrack(_ snapshot: SystemMediaSnapshot) {
        let track = SpotifyHistoryTrack(
            id: snapshot.spotifyURI ?? "\(snapshot.title)\u{1F}::\(snapshot.artist)",
            spotifyURI: snapshot.spotifyURI ?? "",
            title: snapshot.title,
            artist: snapshot.artist.isEmpty ? snapshot.album : snapshot.artist,
            artwork: snapshot.artwork
        )

        spotifyRecentlyPlayed.removeAll { $0.id == track.id }
        spotifyRecentlyPlayed.insert(track, at: 0)
        spotifyRecentlyPlayed = Array(spotifyRecentlyPlayed.prefix(8))
    }

    private func readChromeSnapshot() -> SystemMediaSnapshot? {
        let accessScript = """
        tell application "Google Chrome"
            return name
        end tell
        """
        var accessError: NSDictionary?
        guard NSAppleScript(source: accessScript)?.executeAndReturnError(&accessError) != nil else {
            if let accessError {
                print("Chrome automation access failed: \(accessError)")
            }
            return nil
        }

        let script = """
        tell application "Google Chrome"
            repeat with browserWindow in windows
                repeat with browserTab in tabs of browserWindow
                    try
                        set mediaResult to execute javascript "(() => { const elements = [...document.querySelectorAll('audio,video')].filter(element => !element.ended && element.readyState >= 2); const media = elements.find(element => !element.paused) || elements[0]; if (!media) return ''; const title = (document.title || location.hostname || 'Chrome audio').split('||').join(' '); const duration = Number.isFinite(media.duration) ? media.duration : 0; const artwork = media.poster || ''; return title + '||' + media.currentTime + '||' + duration + '||' + (!media.paused) + '||' + encodeURIComponent(artwork); })()" in browserTab

                        if mediaResult is not missing value and mediaResult is not "" then
                            return mediaResult
                        end if
                    end try
                end repeat
            end repeat
        end tell
        """

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error),
              let value = result.stringValue
        else { return nil }

        return browserSnapshot(from: value, appName: "Google Chrome", bundleIdentifier: "com.google.Chrome")
    }

    private func readSafariSnapshot() -> SystemMediaSnapshot? {
        let script = """
        tell application "Safari"
            if it is not running then return missing value
            repeat with browserWindow in windows
                repeat with browserTab in tabs of browserWindow
                    try
                        set mediaResult to do JavaScript "(() => { const elements = [...document.querySelectorAll('audio,video')].filter(element => !element.ended && element.readyState >= 2); const media = elements.find(element => !element.paused) || elements[0]; if (!media) return ''; const title = (document.title || location.hostname || 'Safari audio').split('||').join(' '); const duration = Number.isFinite(media.duration) ? media.duration : 0; const artwork = media.poster || ''; return title + '||' + media.currentTime + '||' + duration + '||' + (!media.paused) + '||' + encodeURIComponent(artwork); })()" in browserTab
                        if mediaResult is not missing value and mediaResult is not "" then return mediaResult
                    end try
                end repeat
            end repeat
        end tell
        """

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error),
              let value = result.stringValue
        else { return nil }

        return browserSnapshot(from: value, appName: "Safari", bundleIdentifier: "com.apple.Safari")
    }

    private func browserSnapshot(
        from value: String,
        appName: String,
        bundleIdentifier: String
    ) -> SystemMediaSnapshot? {
        let fields = value.components(separatedBy: "||")
        guard fields.count >= 5,
              let position = Double(fields[fields.count - 4]),
              let duration = Double(fields[fields.count - 3]),
              let isPlaying = Bool(fields[fields.count - 2])
        else { return nil }

        let title = fields.dropLast(4).joined(separator: "||")
        let artworkURL = fields[fields.count - 1].removingPercentEncoding
        let artwork = artworkURL
            .flatMap(URL.init(string:))
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap(NSImage.init(data:))
        return SystemMediaSnapshot(
            title: title.isEmpty ? "Audio detected" : title,
            artist: appName,
            album: "",
            appName: appName,
            appBundleIdentifier: bundleIdentifier,
            appColor: .systemBlue,
            artwork: artwork,
            isPlaying: isPlaying,
            position: max(0, position),
            duration: max(0, duration),
            updatedAt: Date(),
            spotifyURI: nil
        )
    }

    private func readSnapshot(for player: MediaPlayer) -> (player: MediaPlayer, snapshot: SystemMediaSnapshot)? {
        if player == .chrome, let snapshot = readChromeSnapshot() {
            return (player, snapshot)
        }
        if player == .safari, let snapshot = readSafariSnapshot() {
            return (player, snapshot)
        }

        let script = """
        if application "\(player.applicationName)" is running then
            tell application "\(player.applicationName)"
                if player state is playing or player state is paused then
                    set playbackState to "paused"
                    if player state is playing then set playbackState to "playing"
                    if "\(player == .spotify ? "true" : "false")" is "true" then
                        return {name of current track as text, artist of current track as text, album of current track as text, player position as real, duration of current track as real, playbackState, spotify url of current track as text}
                    end if
                    return {name of current track as text, artist of current track as text, album of current track as text, player position as real, duration of current track as real, playbackState, ""}
                end if
            end tell
        end if
        return missing value
        """

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error),
              result.numberOfItems == 7,
              let title = result.atIndex(1)?.stringValue,
              let artist = result.atIndex(2)?.stringValue,
              let album = result.atIndex(3)?.stringValue,
              let position = result.atIndex(4)?.doubleValue,
              let duration = result.atIndex(5)?.doubleValue,
              let state = result.atIndex(6)?.stringValue
        else {
            return nil
        }

        // Spotify exposes track duration in milliseconds, while Music and
        // the player position values use seconds. Keep the view's model in
        // one unit so the progress ratio and timestamps stay accurate.
        let durationInSeconds: Double
        switch player {
        case .spotify:
            durationInSeconds = duration > 10_000 ? duration / 1_000 : duration
        case .music:
            durationInSeconds = duration
        case .chrome, .safari:
            durationInSeconds = duration
        }

        let snapshot = SystemMediaSnapshot(
            title: title,
            artist: artist,
            album: album,
            appName: player.displayName,
            appBundleIdentifier: player.bundleIdentifier,
            appColor: player.color,
            artwork: readArtwork(for: player),
            isPlaying: state == "playing",
            position: max(0, position),
            duration: max(0, durationInSeconds),
            updatedAt: Date(),
            spotifyURI: player == .spotify ? result.atIndex(7)?.stringValue : nil
        )
        return (player, snapshot)
    }

    private func runCommand(_ player: MediaPlayer, command: String) {
        if player.isBrowser {
            runBrowserPlaybackCommand(for: player)
            return
        }

        let script = """
        if application "\(player.applicationName)" is running then
            tell application "\(player.applicationName)"
                \(command)
            end tell
        end if
        """

        var error: NSDictionary?
        _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error {
            print("Glimpse media command failed for \(player.displayName): \(error)")
        }
    }

    private func runBrowserPlaybackCommand(for player: MediaPlayer) {
        let javascript = "(() => { const elements = [...document.querySelectorAll('audio,video')].filter(element => !element.ended && element.readyState >= 2); const media = elements.find(element => !element.paused) || elements[0]; if (!media) return ''; if (media.paused) { media.play(); } else { media.pause(); } return 'done'; })()"
        let application = player == .chrome ? "Google Chrome" : "Safari"
        let command = player == .chrome ? "execute javascript \"\(javascript)\" in browserTab" : "do JavaScript \"\(javascript)\" in browserTab"
        let script = """
        tell application "\(application)"
            repeat with browserWindow in windows
                repeat with browserTab in tabs of browserWindow
                    try
                        set resultValue to \(command)
                        if resultValue is not missing value and resultValue is not "" then return resultValue
                    end try
                end repeat
            end repeat
        end tell
        """

        var error: NSDictionary?
        _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    private func readArtwork(for player: MediaPlayer) -> NSImage? {
        let script: String
        switch player {
        case .music:
            script = """
            if application "Music" is running then
                tell application "Music"
                    if player state is playing or player state is paused then
                        return data of artwork 1 of current track
                    end if
                end tell
            end if
            return missing value
            """
        case .spotify:
            script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    if player state is playing or player state is paused then
                        return artwork url of current track as text
                    end if
                end tell
            end if
            return missing value
            """
        case .chrome, .safari:
            return nil
        }

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error) else {
            return nil
        }

        switch player {
        case .music:
            return NSImage(data: result.data)
        case .spotify:
            guard let urlString = result.stringValue,
                  let url = URL(string: urlString),
                  let data = try? Data(contentsOf: url)
            else {
                return nil
            }
            return NSImage(data: data)
        case .chrome, .safari:
            return nil
        }
    }
}

private enum MediaPlayer: CaseIterable, Equatable {
    case spotify
    case music
    case chrome
    case safari

    var isBrowser: Bool {
        self == .chrome || self == .safari
    }

    var applicationName: String {
        switch self {
        case .spotify: return "Spotify"
        case .music: return "Music"
        case .chrome: return "Google Chrome"
        case .safari: return "Safari"
        }
    }

    var displayName: String {
        switch self {
        case .spotify: return "Spotify"
        case .music: return "Apple Music"
        case .chrome: return "Google Chrome"
        case .safari: return "Safari"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .spotify: return "com.spotify.client"
        case .music: return "com.apple.Music"
        case .chrome: return "com.google.Chrome"
        case .safari: return "com.apple.Safari"
        }
    }

    var color: NSColor {
        switch self {
        case .spotify: return .systemGreen
        case .music: return .systemPink
        case .chrome: return .systemBlue
        case .safari: return .systemBlue
        }
    }
}
