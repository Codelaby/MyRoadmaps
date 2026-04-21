import SwiftUI
import AVFoundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: Song Model
struct SongModelInfo {
    var duration: Duration = .zero
    var songName: String = "Unknown"
    var artistName: String = "Unknown"
    var albumArtData: Data? = nil

    #if canImport(UIKit)
    var albumArtImage: UIImage? {
        guard let data = albumArtData else { return nil }
        return UIImage(data: data)
    }
    #elseif canImport(AppKit)
    var albumArtImage: NSImage? {
        guard let data = albumArtData else { return nil }
        return NSImage(data: data)
    }
    #endif
}

enum MediaPlayStatus: Equatable {
    case playing
    case paused
    case stopped
}


// MARK: AudioDelegate — sin cambios
@MainActor
fileprivate class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: AudioManager
@MainActor
@Observable
class AudioManager {
    static let shared = AudioManager()
    private init() {}

    var playStatus: MediaPlayStatus = .stopped
    var currentTime: Duration = .seconds(0)
    var durationTime: Duration = .seconds(0)
    var songInfo = SongModelInfo()
    var shouldLoop = false  // ← Nuevo: control de repetición

    var isPlaying: Bool {
         playStatus == .playing
     }
    
    @ObservationIgnored private var delegate: AudioDelegate?
    @ObservationIgnored private var audioPlayer: AVAudioPlayer?
    @ObservationIgnored private var playbackTimer: Timer?

    func loadAudio(filename: String) {
        guard let path = Bundle.main.path(forResource: filename, ofType: "mp3") else {
            print("[shark] \(filename) not found")
            return
        }
        print(path)
        do {
            let url = URL(fileURLWithPath: path)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            durationTime = .seconds(audioPlayer?.duration ?? 0)
            extractMetadata(from: url)

            delegate = AudioDelegate { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    print("finish wait")
                    
//                    self.audioPlayer?.currentTime = self.durationTime.toSeconds()
//                    self.playStatus = .stopped
//                    
//                    
//                    try! await Task.sleep(for: .seconds(1))
//                    print("finished")

                    if self.shouldLoop {
                        // Reiniciar y seguir reproduciendo
                        self.audioPlayer?.currentTime = 0
                        self.currentTime = .seconds(0)
                        self.audioPlayer?.play()
                        self.playStatus = .playing
                    } else {
                        // Detener completamente
                        self.playStatus = .stopped
                        self.currentTime = .seconds(0)
                        self.stopPlaybackTimer()
                        self.audioPlayer?.currentTime = 0
                    }
                }
            }
            audioPlayer?.delegate = delegate
            audioPlayer?.prepareToPlay()
        } catch {
            print("[shark] audioPlayer cannot load \(path):", error)
        }
    }

    func play() {
        print("play")
        audioPlayer?.play()
        playStatus = .playing
        startPlaybackTimer()
    }

    func pause() {
        audioPlayer?.pause()
        playStatus = .paused
        stopPlaybackTimer()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        playStatus = .stopped
        currentTime = .seconds(0)
        stopPlaybackTimer()
    }
    
    func playOrPause() {
        switch playStatus {
        case .playing:
            pause()
            
        case .paused:
            // Si está pausado, reanudar desde donde estaba
            play()
            
        case .stopped:
            // Si está stopped, empezar desde el principio
            audioPlayer?.currentTime = 0
            play()
        }
    }
    
    // Nuevo: Toggle para loop
    func toggleLoop() {
        shouldLoop.toggle()
    }

    func seekTo(_ time: Duration) {
        guard let player = audioPlayer else { return }
        let seconds = max(0, min(time.toSeconds(), durationTime.toSeconds()))
        player.currentTime = seconds
        currentTime = .seconds(seconds)
    }

    func setCurrentTime(_ time: Duration) { seekTo(time) }
    func setCurrentTime(_ time: Double)   { seekTo(.seconds(time)) }

    func seekBackwards(_ interval: Duration) { seekTo(currentTime - interval) }
    func seekForward(_ interval: Duration)   { seekTo(currentTime + interval) }

    // MARK: Timer
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer, self.isPlaying else {
                    self?.stopPlaybackTimer()
                    return
                }
                self.currentTime = .seconds(player.currentTime)
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: Metadata
    private func extractMetadata(from url: URL) {
        songInfo = SongModelInfo()
        Task {
            do {
                let asset = AVURLAsset(url: url)
                let duration = try await asset.load(.duration)
                let metadata = try await asset.load(.commonMetadata)

                var info = SongModelInfo()
                info.duration = .seconds(CMTimeGetSeconds(duration))

                for item in metadata {
                    guard let key = item.commonKey?.rawValue else { continue }
                    switch key {
                    case "title":
                        info.songName = (try? await item.load(.stringValue)) ?? "Unknown"
                    case "artist":
                        info.artistName = (try? await item.load(.stringValue)) ?? "Unknown"
                    case "artwork":
                        info.albumArtData = try? await item.load(.dataValue)
                    default: break
                    }
                }
                // Una sola asignación al final → un solo ciclo de observación
                songInfo = info
            } catch {
                print("[shark] Error loading metadata: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Duration helper
extension Duration {
    func toSeconds() -> Double {
        let components = self.components
        return Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }
}

// MARK: Simple Play Music
struct SimplePlayMusic: View {
    @State private var audioManager = AudioManager.shared
    
    @State private var sliderValue: Double = 0
    @State private var isDragging = false
    
    let songFileName = "Yuna - Ice Cream"
        
    var body: some View {
        VStack {
            GroupBox("Audio metadata") {
#if os(iOS)
                if let image = audioManager.songInfo.albumArtImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                }
#elseif os(macOS)
                if let image = audioManager.songInfo.albumArtImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                }
#endif
                LabeledContent("Song name", content: { Text(.init(audioManager.songInfo.songName))})
                LabeledContent("Artist", value: audioManager.songInfo.artistName)
                LabeledContent("Duration", value: audioManager.songInfo.duration, format: .time(pattern: .minuteSecond))
            }
            .font(.caption)
            .padding(.horizontal)
        
            WaveHSlider(
                value: $sliderValue,
                in: 0...audioManager.durationTime.toSeconds(),
                isPlaying: audioManager.isPlaying,
                onEditingChanged: { editing in
                    isDragging = editing
                    if !editing {
                        audioManager.seekTo(.seconds(sliderValue))
                    }
                }
            )
            .sliderThumbVisibility(.hidden)
            .padding(.horizontal)
            .onChange(of: audioManager.currentTime) { _, newValue in
                if !isDragging {
                    sliderValue = newValue.toSeconds()
                }
            }
            
            AudioTrackTimeDisplay(
                songElapsed: Duration.seconds(sliderValue),
                songDuration: audioManager.songInfo.duration
            )
            .padding(.horizontal)


            // Control buttons
            HStack {
                Button(audioManager.isPlaying ? "Pause" : "Play") {
                    if audioManager.isPlaying {
                        audioManager.pause()
                    } else {
                        audioManager.play()
                    }
                }
                
                Button("Stop") {
                    audioManager.stop()
                }
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .task {
            audioManager.loadAudio(filename: songFileName)
        }
    }
}

// MARK: Preview
#Preview {
    SimplePlayMusic()
       // .environment(\.layoutDirection, .rightToLeft)
}
