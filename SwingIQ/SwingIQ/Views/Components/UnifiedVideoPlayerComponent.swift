//
//  UnifiedVideoPlayerComponent.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//  Unified video player component that consolidates all video player functionality
//

import SwiftUI
import AVKit
import Combine

// MARK: - Configuration

struct VideoPlayerConfiguration {
    let showFullscreenButton: Bool
    let showSpeedControls: Bool
    let showTimeDisplay: Bool
    let showScrubber: Bool
    let showPlayPauseButton: Bool
    let showSeekButtons: Bool
    let showFrameStepButton: Bool
    let autoHideControls: Bool
    let autoHideDelay: TimeInterval
    let playbackSpeeds: [Float]
    let overlaySupported: Bool
    
    static let standard = VideoPlayerConfiguration(
        showFullscreenButton: true,
        showSpeedControls: true,
        showTimeDisplay: true,
        showScrubber: true,
        showPlayPauseButton: true,
        showSeekButtons: true,
        showFrameStepButton: true,
        autoHideControls: true,
        autoHideDelay: 3.0,
        playbackSpeeds: [0.25, 0.5, 1.0, 1.5, 2.0],
        overlaySupported: true
    )
    
    static let minimal = VideoPlayerConfiguration(
        showFullscreenButton: false,
        showSpeedControls: false,
        showTimeDisplay: true,
        showScrubber: true,
        showPlayPauseButton: true,
        showSeekButtons: false,
        showFrameStepButton: false,
        autoHideControls: false,
        autoHideDelay: 3.0,
        playbackSpeeds: [0.5, 1.0, 2.0],
        overlaySupported: false
    )
    
    static let fullscreen = VideoPlayerConfiguration(
        showFullscreenButton: true,
        showSpeedControls: true,
        showTimeDisplay: true,
        showScrubber: true,
        showPlayPauseButton: true,
        showSeekButtons: true,
        showFrameStepButton: true,
        autoHideControls: true,
        autoHideDelay: 3.0,
        playbackSpeeds: [0.5, 1.0, 1.5, 2.0],
        overlaySupported: true
    )
}

// MARK: - Video Player State

@MainActor
class VideoPlayerState: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1.0
    @Published var playbackSpeed: Float = 1.0
    @Published var isFullscreen = false
    @Published var showingControls = true
    @Published var videoRect: CGRect = .zero
    
    private var timeObserver: Any?
    private var statusObserver: AnyCancellable?
    private var controlsTimer: Timer?
    
    func setupPlayer(with url: URL, autoPlay: Bool = false) {
        print("📹 Setting up unified video player with URL: \(url)")
        
        player = AVPlayer(url: url)
        player?.actionAtItemEnd = .pause
        
        // Set up time observer
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            DispatchQueue.main.async {
                let timeSeconds = time.seconds
                self?.currentTime = timeSeconds.isFinite ? timeSeconds : 0
            }
        }
        
        // Monitor player status
        statusObserver = player?.currentItem?
            .publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] status in
                print("📹 Player status: \(status.rawValue)")
                switch status {
                case .readyToPlay:
                    print("📹 Video ready to play")
                    Task { @MainActor in
                        await self?.loadDuration()
                        if autoPlay {
                            self?.player?.play()
                        }
                    }
                case .failed:
                    if let error = self?.player?.currentItem?.error {
                        print("❌ Video failed to load: \(error.localizedDescription)")
                    }
                case .unknown:
                    print("📹 Player status unknown")
                @unknown default:
                    print("📹 Unknown player status")
                }
            }
    }
    
    private func loadDuration() async {
        guard let playerItem = player?.currentItem else { return }
        
        var attempts = 0
        let maxAttempts = 20
        
        while attempts < maxAttempts {
            let itemDuration = playerItem.duration
            
            if itemDuration.isValid && !itemDuration.isIndefinite {
                let durationSeconds = itemDuration.seconds
                if durationSeconds.isFinite && durationSeconds > 0 {
                    self.duration = durationSeconds
                    print("📹 Duration loaded: \(durationSeconds) seconds")
                    return
                }
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        print("⚠️ Could not load video duration, using fallback")
        self.duration = 1.0
    }
    
    func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.rate = playbackSpeed
            player?.play()
        }
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }
    
    func cyclePlaybackSpeed(speeds: [Float]) {
        if let currentIndex = speeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % speeds.count
            setPlaybackSpeed(speeds[nextIndex])
        }
    }
    
    func seekToTime(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    func seekToBeginning() {
        seekToTime(0)
    }
    
    func seekToEnd() {
        seekToTime(duration)
    }
    
    func stepFrame(forward: Bool = true) {
        let frameTime = 1.0 / 30.0
        let newTime = forward ? 
            min(currentTime + frameTime, duration) :
            max(currentTime - frameTime, 0)
        seekToTime(newTime)
    }
    
    func toggleFullscreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFullscreen.toggle()
        }
    }
    
    func toggleControlsVisibility(autoHideDelay: TimeInterval = 3.0) {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingControls.toggle()
        }
        
        controlsTimer?.invalidate()
        if showingControls && autoHideDelay > 0 {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self?.showingControls = false
                    }
                }
            }
        }
    }
    
    func cleanup() {
        player?.pause()
        controlsTimer?.invalidate()
        statusObserver?.cancel()
        
        if let player = player, let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    deinit {
        // Cleanup will happen when the object is deallocated
        // Cannot directly cleanup @MainActor properties in deinit
    }
}

// MARK: - Custom Video Player UIKit Component

class UnifiedPlayerView: UIView {
    var playerLayer: AVPlayerLayer?
    var onVideoRectChange: ((CGRect) -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        
        // Notify when video rect changes
        if let videoRect = playerLayer?.videoRect, 
           videoRect.width > 0 && videoRect.height > 0 {
            onVideoRectChange?(videoRect)
        }
    }
    
    var currentVideoRect: CGRect {
        playerLayer?.videoRect ?? .zero
    }
}

struct UnifiedCustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    let onRectChange: (CGRect) -> Void
    
    func makeUIView(context: Context) -> UnifiedPlayerView {
        let view = UnifiedPlayerView()
        view.backgroundColor = UIColor.black
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        
        view.layer.addSublayer(playerLayer)
        view.playerLayer = playerLayer
        view.onVideoRectChange = onRectChange
        
        return view
    }
    
    func updateUIView(_ uiView: UnifiedPlayerView, context: Context) {
        uiView.playerLayer?.frame = uiView.bounds
        
        if uiView.playerLayer?.player !== player {
            uiView.playerLayer?.player = player
        }
        
        uiView.onVideoRectChange = onRectChange
    }
}

// MARK: - Unified Video Player Component

struct UnifiedVideoPlayerComponent<Overlay: View>: View {
    let url: URL
    let configuration: VideoPlayerConfiguration
    let overlay: () -> Overlay
    
    @StateObject private var playerState = VideoPlayerState()
    
    // Optional callbacks
    var onVideoRectChange: ((CGRect) -> Void)?
    var onTimeChange: ((Double) -> Void)?
    var onPlaybackStateChange: ((Bool) -> Void)?
    var externalControlsOpacity: Double?
    
    init(
        url: URL,
        configuration: VideoPlayerConfiguration = .standard,
        onVideoRectChange: ((CGRect) -> Void)? = nil,
        onTimeChange: ((Double) -> Void)? = nil,
        onPlaybackStateChange: ((Bool) -> Void)? = nil,
        externalControlsOpacity: Double? = nil,
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }
    ) {
        self.url = url
        self.configuration = configuration
        self.onVideoRectChange = onVideoRectChange
        self.onTimeChange = onTimeChange
        self.onPlaybackStateChange = onPlaybackStateChange
        self.externalControlsOpacity = externalControlsOpacity
        self.overlay = overlay
    }
    
    var body: some View {
        ZStack {
            
            if playerState.isFullscreen {
                fullscreenView
            } else {
                standardView
            }
        }
        .onAppear {
            playerState.setupPlayer(with: url)
        }
        .onDisappear {
            playerState.cleanup()
        }
        .onChange(of: playerState.currentTime) { _, newTime in
            onTimeChange?(newTime)
        }
        .onChange(of: playerState.isPlaying) { _, isPlaying in
            onPlaybackStateChange?(isPlaying)
        }
        .onReceive(playerState.$isPlaying) { isPlaying in
            onPlaybackStateChange?(isPlaying)
        }
    }
    
    // MARK: - Standard View
    
    private var standardView: some View {
        ZStack {
            // Video player
            if let player = playerState.player {
                UnifiedCustomVideoPlayer(player: player) { rect in
                    playerState.videoRect = rect
                    onVideoRectChange?(rect)
                }
                .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                    playerState.isPlaying = (status == .playing)
                }
            }
            
            // Overlay content
            if configuration.overlaySupported {
                overlay()
                    .allowsHitTesting(false)
            }
            
            // Controls overlay
            if playerState.showingControls {
                controlsOverlay
                    .transition(.opacity)
                    .opacity(externalControlsOpacity ?? 1.0)
            }
        }
        .onTapGesture {
            if configuration.autoHideControls {
                playerState.toggleControlsVisibility(autoHideDelay: configuration.autoHideDelay)
            }
        }
    }
    
    // MARK: - Fullscreen View
    
    private var fullscreenView: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea(.all)
                
                // Video player
                if let player = playerState.player {
                    UnifiedCustomVideoPlayer(player: player) { rect in
                        playerState.videoRect = rect
                        onVideoRectChange?(rect)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                }
                
                // Overlay content
                if configuration.overlaySupported {
                    overlay()
                        .allowsHitTesting(false)
                }
                
                // Fullscreen controls
                if playerState.showingControls {
                    fullscreenControlsOverlay(geometry: geometry)
                        .transition(.opacity)
                        .opacity(externalControlsOpacity ?? 1.0)
                }
            }
        }
        .onTapGesture {
            if configuration.autoHideControls {
                playerState.toggleControlsVisibility(autoHideDelay: configuration.autoHideDelay)
            }
        }
    }
    
    // MARK: - Controls Overlay
    
    private var controlsOverlay: some View {
        VStack {
            // Top controls
            HStack {
                Spacer()
                
                if configuration.showFullscreenButton {
                    Button(action: playerState.toggleFullscreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: 12) {
                // Time scrubber
                if configuration.showScrubber {
                    timeSlider
                }
                
                // Main controls
                mainControls
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private func fullscreenControlsOverlay(geometry: GeometryProxy) -> some View {
        VStack {
            // Top controls
            HStack {
                if configuration.showFullscreenButton {
                    Button(action: playerState.toggleFullscreen) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, max(20, geometry.safeAreaInsets.top))
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: 12) {
                if configuration.showScrubber {
                    timeSlider
                }
                
                mainControls
            }
            .padding(.horizontal, 20)
            .padding(.bottom, max(40, geometry.safeAreaInsets.bottom + 20))
        }
    }
    
    // MARK: - Control Components
    
    private var timeSlider: some View {
        VStack(spacing: 6) {
            if configuration.showTimeDisplay {
                HStack {
                    Text(formatTime(playerState.currentTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(formatTime(playerState.duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Slider(
                value: $playerState.currentTime,
                in: 0...max(1.0, playerState.duration.isFinite ? playerState.duration : 1.0)
            ) { editing in
                if !editing {
                    playerState.seekToTime(playerState.currentTime)
                }
            }
            .accentColor(Color(hex: "00B04F"))
        }
    }
    
    private var mainControls: some View {
        HStack {
            // Speed controls
            if configuration.showSpeedControls {
                speedControls
            }
            
            Spacer()
            
            // Playback controls
            HStack(spacing: 16) {
                if configuration.showSeekButtons {
                    Button(action: playerState.seekToBeginning) {
                        Image(systemName: "backward.end.fill")
                            .foregroundColor(.white)
                    }
                }
                
                if configuration.showPlayPauseButton {
                    Button(action: playerState.togglePlayback) {
                        Image(systemName: playerState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                if configuration.showSeekButtons {
                    Button(action: playerState.seekToEnd) {
                        Image(systemName: "forward.end.fill")
                            .foregroundColor(.white)
                    }
                }
                
                if configuration.showFrameStepButton {
                    Button(action: { playerState.stepFrame() }) {
                        Image(systemName: "forward.frame.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            
            if configuration.showSpeedControls {
                Spacer()
            }
        }
    }
    
    private var speedControls: some View {
        HStack(spacing: 8) {
            ForEach(configuration.playbackSpeeds, id: \.self) { speed in
                Button(action: {
                    playerState.setPlaybackSpeed(speed)
                }) {
                    Text(speed == 1.0 ? "1x" : String(format: "%.2gx", speed))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(playerState.playbackSpeed == speed ? Color(hex: "00B04F") : .white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(playerState.playbackSpeed == speed ? Color(hex: "00B04F").opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite else { return "0:00" }
        let safeTime = max(0, time)
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Convenience Extensions

extension UnifiedVideoPlayerComponent where Overlay == EmptyView {
    init(
        url: URL,
        configuration: VideoPlayerConfiguration = .standard,
        onVideoRectChange: ((CGRect) -> Void)? = nil,
        onTimeChange: ((Double) -> Void)? = nil,
        onPlaybackStateChange: ((Bool) -> Void)? = nil,
        externalControlsOpacity: Double? = nil
    ) {
        self.url = url
        self.configuration = configuration
        self.onVideoRectChange = onVideoRectChange
        self.onTimeChange = onTimeChange
        self.onPlaybackStateChange = onPlaybackStateChange
        self.externalControlsOpacity = externalControlsOpacity
        self.overlay = { EmptyView() }
    }
}


