import SwiftUI
import AVFoundation

struct VoiceNoteView: View {
    private let url: URL
    private let isSending: Bool
    private let sendProgress: Double?
    private let onCancel: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var playback: VoiceNotePlaybackController
    @State private var waveform: [Float] = []

    init(url: URL, isSending: Bool, sendProgress: Double?, onCancel: (() -> Void)?) {
        self.url = url
        self.isSending = isSending
        self.sendProgress = sendProgress
        self.onCancel = onCancel
        _playback = StateObject(wrappedValue: VoiceNotePlaybackController(url: url))
    }

    private var samples: [Float] {
        if waveform.isEmpty {
            return Array(repeating: 0.25, count: 64)
        }
        return waveform
    }

    private var backgroundColor: Color {
        NupChatTheme.secondaryBackground(colorScheme)
    }

    private var borderColor: Color {
        NupChatTheme.divider(colorScheme)
    }

    private var durationText: String {
        let duration = playback.duration
        guard duration.isFinite, duration > 0 else { return "--:--" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var currentText: String {
        let current = playback.currentTime
        guard current.isFinite, current > 0 else { return "00:00" }
        let minutes = Int(current) / 60
        let seconds = Int(current) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var playbackLabel: String {
        playback.isPlaying ? currentText + "/" + durationText : durationText
    }

    var body: some View {
        HStack(spacing: 12) {
            // Modern play button
            Button(action: playback.togglePlayback) {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(NupChatTheme.accentGradient)
                    )
            }
            .buttonStyle(.plain)
            .subtleShadow(colorScheme: colorScheme)

            WaveformView(
                samples: samples,
                playbackProgress: playback.progress,
                sendProgress: sendProgress,
                onSeek: { fraction in
                    playback.seek(to: fraction)
                },
                isInteractive: playback.isPlaying
            )

            Text(playbackLabel)
                .font(.bitchatMono(size: 12))
                .foregroundColor(NupChatTheme.secondaryText(colorScheme))

            if let onCancel = onCancel, isSending {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(NupChatTheme.error))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: NupChatTheme.cardCornerRadius, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NupChatTheme.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .subtleShadow(colorScheme: colorScheme)
        .task {
            // Defer loading to let UI settle after view appears
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            playback.loadDuration()
            await withCheckedContinuation { continuation in
                WaveformCache.shared.waveform(for: url, completion: { bins in
                    waveform = bins
                    continuation.resume()
                })
            }
        }
        .onChange(of: url) { newValue in
            WaveformCache.shared.waveform(for: newValue, completion: { bins in
                self.waveform = bins
            })
            playback.replaceURL(newValue)
        }
        .onDisappear {
            playback.stop()
        }
    }
}
