import AppKit
import Combine

struct SystemMediaSnapshot {
    let title: String
    let artist: String
    let album: String
    let appName: String
    let appColor: NSColor
    let artwork: NSImage?
    let isPlaying: Bool
    let position: Double
    let duration: Double
    let updatedAt: Date
}

final class SystemMediaStore: ObservableObject {
    @Published private(set) var snapshot: SystemMediaSnapshot?

    private var pollTimer: Timer?
    private var activePlayer: MediaPlayer?
    private var isPolling = false

    func start() {
        guard pollTimer == nil else {
            refresh()
            return
        }

        refresh()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
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

            let result = playing ?? results.first

            DispatchQueue.main.async {
                guard let self else { return }
                self.activePlayer = result?.player
                self.snapshot = result?.snapshot
                self.isPolling = false
            }
        }
    }

    private func readSnapshot(for player: MediaPlayer) -> (player: MediaPlayer, snapshot: SystemMediaSnapshot)? {
        let script = """
        if application "\(player.applicationName)" is running then
            tell application "\(player.applicationName)"
                if player state is playing or player state is paused then
                    set playbackState to "paused"
                    if player state is playing then set playbackState to "playing"
                    return {name of current track as text, artist of current track as text, album of current track as text, player position as real, duration of current track as real, playbackState}
                end if
            end tell
        end if
        return missing value
        """

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error),
              result.numberOfItems == 6,
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
        }

        let snapshot = SystemMediaSnapshot(
            title: title,
            artist: artist,
            album: album,
            appName: player.displayName,
            appColor: player.color,
            artwork: readArtwork(for: player),
            isPlaying: state == "playing",
            position: max(0, position),
            duration: max(0, durationInSeconds),
            updatedAt: Date()
        )
        return (player, snapshot)
    }

    private func runCommand(_ player: MediaPlayer, command: String) {
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
            print("Notch media command failed for \(player.displayName): \(error)")
        }
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
        }
    }
}

private enum MediaPlayer: CaseIterable {
    case spotify
    case music

    var applicationName: String {
        switch self {
        case .spotify: return "Spotify"
        case .music: return "Music"
        }
    }

    var displayName: String {
        switch self {
        case .spotify: return "Spotify"
        case .music: return "Apple Music"
        }
    }

    var color: NSColor {
        switch self {
        case .spotify: return .systemGreen
        case .music: return .systemPink
        }
    }
}
