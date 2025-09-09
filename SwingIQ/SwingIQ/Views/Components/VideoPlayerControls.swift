//
//  VideoPlayerControls.swift
//  SwingIQ
//
//  Video player controls component
//

import SwiftUI
import AVKit

struct VideoPlayerControls: View {
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var playbackSpeed: Float
    @Binding var isPlaying: Bool
    @Binding var showingControls: Bool
    
    let onSeek: (Double) -> Void
    let onTogglePlayback: () -> Void
    let onCycleSpeed: () -> Void
    
    private let playbackSpeeds: [Float] = [0.5, 1.0, 1.5, 2.0]
    
    var body: some View {
        VStack(spacing: 12) {
            // Scrubber
            timelineSlider
            
            // Control buttons
            HStack {
                // Left: Speed control
                speedControlButton
                
                Spacer()
                
                // Center: Play button
                playPauseButton
                
                Spacer()
                
                // Right: Time display
                timeDisplay
            }
        }
    }
    
    // MARK: - Components
    
    private var timelineSlider: some View {
        Slider(value: $currentTime, in: 0...max(1.0, duration.isFinite ? duration : 1.0)) { editing in
            if !editing {
                onSeek(currentTime)
            }
        }
        .accentColor(.green)
        .frame(height: 40)
    }
    
    private var speedControlButton: some View {
        Button(action: {
            print("🎯 Speed button tapped! Current speed: \(playbackSpeed)")
            onCycleSpeed()
        }) {
            Text("\(playbackSpeed == 1.0 ? "1x" : String(format: "%.1fx", playbackSpeed))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 48, height: 36)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var playPauseButton: some View {
        Button(action: {
            print("🎯 Play button tapped! Current state: \(isPlaying)")
            onTogglePlayback()
        }) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.black.opacity(0.7)))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isPlaying ? "Pause video" : "Play video")
    }
    
    private var timeDisplay: some View {
        Text("\(formatTime(currentTime)) / \(formatTime(duration))")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 80)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite else { return "0:00" }
        let safeTime = max(0, time)
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
