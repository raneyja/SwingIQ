//
//  SwingAnalysisFullScreenView.swift
//  SwingIQ
//
//  Full-screen swing analysis with scrollable results
//

import SwiftUI
import AVKit
import UIKit
import Combine

struct SwingAnalysisFullScreenView: View {
    let video: ProcessingVideo
    @Environment(\.dismiss) private var dismiss
    
    // Optional closure to handle navigation to home
    var onNavigateToHome: (() -> Void)?
    
    // Video player state
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1.0
    @State private var playbackSpeed: Float = 1.0
    
    // MediaPipe is always enabled - no toggle needed
    private let showSkeletonOverlay = true
    
    // Video layout tracking
    @State private var videoRect: CGRect = .zero
    
    // UI state
    @State private var showingControls = true
    @State private var controlsTimer: Timer?
    @State private var timeObserver: Any?
    @State private var statusObserver: AnyCancellable?
    @State private var scrollIndicatorOffset: CGFloat = 0
    @State private var showScrollIndicator = true
    
    private let playbackSpeeds: [Float] = [0.5, 1.0, 1.5, 2.0]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Full-screen Video Player Section
                        videoPlayerSection
                            .frame(height: geometry.size.height)
                            .id("videoSection")
                        
                        // Scrollable Analysis Results
                        analysisResultsSection
                            .background(Color(UIColor.systemBackground))
                            .id("analysisSection")
                    }
                }
                .background(Color.black)
                .ignoresSafeArea(.all, edges: [.bottom, .leading, .trailing])
                .refreshable {
                    // Pull to refresh - navigate to home
                    if let onNavigateToHome = onNavigateToHome {
                        onNavigateToHome()
                    } else {
                        dismiss()
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            // Enhanced swipe down to navigate to home
                            if gesture.translation.height > 80 && gesture.startLocation.y < 200 {
                                if let onNavigateToHome = onNavigateToHome {
                                    onNavigateToHome()
                                } else {
                                    dismiss()
                                }
                            }
                        }
                )
                .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
                    // Check if this notification is for our player
                    if let playerItem = notification.object as? AVPlayerItem,
                       playerItem == player?.currentItem {
                        // Auto-scroll to analysis when video ends
                        withAnimation(.easeInOut(duration: 1.0)) {
                            proxy.scrollTo("analysisSection", anchor: .top)
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            setupPlayer()
            startFloatingAnimation()
            startScrollIndicatorTimer()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func cleanup() {
        player?.pause()
        controlsTimer?.invalidate()
        // Remove time observer to prevent memory leaks
        if let player = player, let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    

    
    // MARK: - Video Player Section
    
    private var videoPlayerSection: some View {
        ZStack {
            Color.black
            
            // Video player
            if let player = player {
                CustomVideoPlayer(player: player) { rect in
                    self.videoRect = rect
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                    isPlaying = (status == .playing)
                }
            }
            
            // MediaPipe skeleton overlay - always visible
            GeometryReader { geo in
                if let poseData = video.poseData, !poseData.isEmpty {
                    MediaPipeOverlay(
                        poseData: poseData,
                        currentTime: currentTime,
                        viewSize: geo.size,
                        videoSize: video.videoSize
                    )
                }
            }
            
            // Fallback message for missing pose data
            if video.poseData?.isEmpty != false {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text("Pose data not available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text("This video hasn't been processed for pose analysis")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3)
                .opacity(0.8)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
            
            // Live data display
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Spacer()
                        // Live data panel - always visible with MediaPipe
                        liveDataPanel
                            .padding(.top, max(geometry.safeAreaInsets.top + 60, 80))
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .allowsHitTesting(false)
            
            // Tap gesture area that doesn't interfere with buttons
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleControlsVisibility()
                }
                .zIndex(-1) // Put behind everything else
            
            // Video controls overlay - put on top
            videoControlsOverlay
                .opacity(showingControls ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showingControls)
                .accessibilityHidden(!showingControls)
                .allowsHitTesting(showingControls) // Only allow hit testing when visible
                .zIndex(100) // High z-index for controls
            
            // MediaPipe is now always enabled - button removed
            
            // Scroll indicator overlay
            scrollIndicatorOverlay
        }
    }
    
    // MARK: - Analysis Results Section
    
    private var analysisResultsSection: some View {
        VStack(spacing: 24) {
            // Analysis Summary Card
            analysisSummaryCard
                .padding(.horizontal, 16)
                .padding(.top, 24)
            
            // Key Metrics Section
            keyMetricsSection
                .padding(.horizontal, 16)
            
            // Areas for Improvement
            areasForImprovementSection
                .padding(.horizontal, 16)
            
            // Recommended Content
            recommendedContentSection
                .padding(.horizontal, 16)
            
            // Action Plan
            actionPlanSection
                .padding(.horizontal, 16)
            
            // Share Button
            shareButtonSection
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
        }
    }
    
    // MARK: - Analysis Summary Card
    
    private var analysisSummaryCard: some View {
        NavigationLink(destination: SwingAnalysisDashboard(analyses: [])) {
            VStack(spacing: 16) {
                HStack {
                    Text("Analysis Summary")
                    .font(.title2)
                    .foregroundColor(.primary)
                    Spacer()
                    
                    // Overall Grade
                    Text("B+")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.green.opacity(0.1)))
                        .overlay(
                            Circle().stroke(Color.green, lineWidth: 2)
                        )
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Strength: Excellent swing path consistency")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Focus Area: Increase club head speed")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Club Head Speed
                NavigationLink(destination: SwingSpeedDashboard(analyses: [])) {
                    MetricDetailCard(
                        title: "Balance",
                        value: "\(Int(getLiveBalance()))",
                        unit: "%",
                        targetRange: "80-95",
                        status: .needsImprovement,
                        description: "Good balance throughout the swing is key for consistency.",
                        isClickable: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Tempo
                NavigationLink(destination: TempoDashboard(analyses: [])) {
                    MetricDetailCard(
                        title: "Tempo",
                        value: String(format: "%.1f:1", getLiveTempo()),
                        unit: "",
                        targetRange: "2.5:1 - 3.5:1",
                        status: .okay,
                        description: "Slightly fast backswing. Try slowing down for better control.",
                        isClickable: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Swing Path
                NavigationLink(destination: SwingPathDashboard(analyses: [])) {
                    MetricDetailCard(
                        title: "Swing Path",
                        value: getLiveSwingPathDescription(),
                        unit: "",
                        targetRange: "On Plane",
                        status: .excellent,
                        description: "Perfect plane consistency. Keep this up!",
                        isClickable: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Body Rotation
                NavigationLink(destination: ProgressTrackingDashboard(analyses: [])) {
                    MetricDetailCard(
                        title: "Hip-Shoulder Separation",
                        value: "32°",
                        unit: "",
                        targetRange: "30-45°",
                        status: .good,
                        description: "Good separation creating power. Room for slight improvement.",
                        isClickable: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Areas for Improvement
    
    private var areasForImprovementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas for Improvement")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Enhanced AI Improvements
                if let enhancedAnalysis = video.enhancedAnalysis {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text("AI-Powered Recommendations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Gemini")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                        
                        if let feedback = enhancedAnalysis.geminiFeedback {
                            Text(feedback)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        ForEach(Array(enhancedAnalysis.geminiImprovements.enumerated()), id: \.offset) { index, improvement in
                            NavigationLink(destination: SwingAnalysisDashboard(analyses: [])) {
                                ImprovementCard(
                                    priority: index == 0 ? .high : .medium,
                                    title: "Improvement \(index + 1)",
                                    description: improvement,
                                    actionable: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    // Fallback to basic improvements
                    NavigationLink(destination: SwingSpeedDashboard(analyses: [])) {
                        ImprovementCard(
                            priority: .high,
                            title: "Increase Club Head Speed",
                            description: "Focus on rotation and timing to generate more speed",
                            actionable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TempoDashboard(analyses: [])) {
                        ImprovementCard(
                            priority: .medium,
                            title: "Improve Tempo",
                            description: "Slow down backswing slightly for better rhythm",
                            actionable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ImprovementCard(
                        priority: .maintain,
                        title: "Maintain Swing Path",
                        description: "Your plane is excellent - keep doing what you're doing",
                        actionable: false
                    )
                }
            }
        }
    }
    
    // MARK: - Recommended Content
    
    private var recommendedContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Content")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // YouTube Recommendations from Enhanced Analysis
                if let enhancedAnalysis = video.enhancedAnalysis, !enhancedAnalysis.youtubeRecommendations.isEmpty {
                    YouTubeRecommendationsView(recommendations: enhancedAnalysis.youtubeRecommendations)
                        .frame(maxWidth: .infinity)
                } else {
                    // Fallback static recommendations
                    NavigationLink(destination: SwingSpeedDashboard(analyses: [])) {
                        RecommendedContentCard(
                            icon: "play.circle.fill",
                            title: "Speed Training Drills",
                            description: "5 exercises to increase clubhead speed",
                            duration: "12 min",
                            type: .video
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TempoDashboard(analyses: [])) {
                        RecommendedContentCard(
                            icon: "play.circle.fill",
                            title: "Tempo Improvement",
                            description: "Perfect your swing timing",
                            duration: "8 min",
                            type: .video
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: SwingAnalysisDashboard(analyses: [])) {
                        RecommendedContentCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Compare to Tour Pros",
                            description: "See how your metrics stack up",
                            duration: "",
                            type: .analysis
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: ProgressTrackingDashboard(analyses: [])) {
                        RecommendedContentCard(
                            icon: "calendar",
                            title: "Track Progress",
                            description: "Monitor improvement over time",
                            duration: "",
                            type: .tracking
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Action Plan
    
    private var actionPlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Action Plan")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                NavigationLink(destination: SwingSpeedDashboard(analyses: [])) {
                    ActionPlanCard(
                        week: "Week 1",
                        focus: "Speed Focus",
                        description: "Practice speed drills 15 min/day, focus on rotation",
                        isActive: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: TempoDashboard(analyses: [])) {
                    ActionPlanCard(
                        week: "Week 2",
                        focus: "Tempo Work",
                        description: "Slow motion swings, metronome practice",
                        isActive: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: SwingAnalysisDashboard(analyses: [])) {
                    ActionPlanCard(
                        week: "Week 3",
                        focus: "Integration",
                        description: "Combine speed and tempo improvements",
                        isActive: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Scroll Indicator Overlay
    
    private var scrollIndicatorOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Scroll for Analysis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: scrollIndicatorOffset)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scrollIndicatorOffset)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.75))
                .cornerRadius(25)
                .opacity(showScrollIndicator && currentTime < duration * 0.8 ? 0.8 : 0) // Hide after 3 seconds and near end of video
                .animation(.easeInOut(duration: 0.5), value: showScrollIndicator)
                
                Spacer()
            }
            .padding(.bottom, 180) // Position higher above video controls
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    

    
    // MARK: - Live Data Panel
    
    private var liveDataPanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let _ = video.poseData, let currentFrame = getCurrentPoseFrame() {
                LiveDataItem(
                    label: "Hip",
                    value: "\(Int(calculateHipAngle(frame: currentFrame)))°",
                    color: .yellow
                )
                
                LiveDataItem(
                    label: "Shoulder", 
                    value: "\(Int(calculateShoulderAngle(frame: currentFrame)))°",
                    color: .cyan
                )
                
                LiveDataItem(
                    label: "Spine",
                    value: "\(Int(calculateSpineAngle(frame: currentFrame)))°", 
                    color: .orange
                )
            } else {
                // Debug: Show detailed info about missing data
                VStack(spacing: 4) {
                    LiveDataItem(
                        label: "Status",
                        value: video.poseData == nil ? "No pose data" : "No frame",
                        color: .red
                    )
                    if let poseData = video.poseData {
                        LiveDataItem(
                            label: "Frames",
                            value: "\(poseData.count)",
                            color: .yellow
                        )
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    // MARK: - Video Controls Overlay
    
    private var videoControlsOverlay: some View {
        VStack {
            Spacer()
            
            // Bottom playback controls only
            playbackControlsView
                .padding(.horizontal, 20)
                .padding(.bottom, 40) // Fixed bottom padding
        }
        .allowsHitTesting(true)
    }
    

    
    private var playbackControlsView: some View {
        VStack(spacing: 12) {
            // Scrubber
            timelineSlider
            
            // Control buttons - properly positioned at bottom
            HStack {
                // Left: Speed control
                speedControlButton
                
                Spacer()
                
                // Center: Play button
                Button(action: {
                    print("🎯 Play button tapped! Current state: \(isPlaying)")
                    togglePlayback()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isPlaying ? "Pause video" : "Play video")
                
                Spacer()
                
                // Right: Time display
                timeDisplay
            }
        }
    }
    
    private var timelineSlider: some View {
        Slider(value: $currentTime, in: 0...max(1.0, duration.isFinite ? duration : 1.0)) { editing in
            if !editing {
                seekToTime(currentTime)
            }
        }
        .accentColor(.green)
        .frame(height: 40)
    }
    
    private var speedControlButton: some View {
        Button(action: {
            print("🎯 Speed button tapped! Current speed: \(playbackSpeed)")
            cyclePlaybackSpeed()
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
    
    private var timeDisplay: some View {
        Text("\(formatTime(currentTime)) / \(formatTime(duration))")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 80)
    }
    
    // MARK: - Share Button Section
    
    private var shareButtonSection: some View {
        Button(action: shareAnalysis) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Share Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .accessibilityLabel("Share swing analysis")
    }
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        player = AVPlayer(url: video.url)
        player?.actionAtItemEnd = .pause
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            let timeSeconds = time.seconds
            currentTime = timeSeconds.isFinite ? timeSeconds : 0
        }
        
        // Auto-play when ready
        statusObserver = player?.currentItem?
            .publisher(for: \.status, options: [.initial, .new])
            .sink { status in
                if status == .readyToPlay {
                    self.player?.play()
                    print("📹 FullScreen Video auto-started after becoming ready")
                }
            }
        
        Task {
            await loadDuration()
        }
    }
    
    @MainActor
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
                    return
                }
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        self.duration = 1.0
    }
    
    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.rate = playbackSpeed
            player?.play()
        }
    }
    
    private func cyclePlaybackSpeed() {
        if let currentIndex = playbackSpeeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % playbackSpeeds.count
            setPlaybackSpeed(playbackSpeeds[nextIndex])
        }
    }
    
    private func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }
    
    private func seekToTime(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func toggleControlsVisibility() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingControls.toggle()
        }
        
        controlsTimer?.invalidate()
        if showingControls {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingControls = false
                }
            }
        }
    }
    
    private func shareAnalysis() {
        // TODO: Implement share functionality
    }
    
    private func startFloatingAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scrollIndicatorOffset = -6
        }
    }
    
    private func startScrollIndicatorTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showScrollIndicator = false
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite else { return "0:00" }
        let safeTime = max(0, time)
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Live Data Helpers
    
    private func getCurrentPoseFrame() -> PoseFrameData? {
        guard let poseData = video.poseData, !poseData.isEmpty else { return nil }
        
        let frameIndex = poseData.enumerated().min {
            abs($0.element.timestamp - currentTime) < abs($1.element.timestamp - currentTime)
        }?.offset ?? 0
        
        return poseData[max(0, min(frameIndex, poseData.count - 1))]
    }
    
    private func calculateHipAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 8,
              frame.confidence[7] > 0.8,
              frame.confidence[8] > 0.8
        else { return 0.0 }
        
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        return abs(atan2(hipVector.y, hipVector.x) * 180 / .pi)
    }
    
    private func calculateShoulderAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 2,
              frame.confidence[1] > 0.8,
              frame.confidence[2] > 0.8
        else { return 0.0 }
        
        let leftShoulder = frame.keypoints[1]
        let rightShoulder = frame.keypoints[2]
        let shoulderVector = CGPoint(x: rightShoulder.x - leftShoulder.x, y: rightShoulder.y - leftShoulder.y)
        return abs(atan2(shoulderVector.y, shoulderVector.x) * 180 / .pi)
    }
    
    private func calculateSpineAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 8,
              frame.confidence[0] > 0.8,
              frame.confidence[7] > 0.8,
              frame.confidence[8] > 0.8
        else { return 0.0 }
        
        let nose = frame.keypoints[0]
        let midHip = CGPoint(
            x: (frame.keypoints[7].x + frame.keypoints[8].x) / 2,
            y: (frame.keypoints[7].y + frame.keypoints[8].y) / 2
        )
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        return abs(atan2(spineVector.x, spineVector.y) * 180 / .pi)
    }
    
    private func getLiveBalance() -> Double {
        guard let currentFrame = getCurrentPoseFrame() else { 
            return (video.analysisResults?.balance ?? 0.5) * 100 
        }
        
        if let poseData = video.poseData, poseData.count >= 2 {
            let frameIndex = poseData.firstIndex { $0.timestamp == currentFrame.timestamp } ?? 0
            guard frameIndex > 0 else { return (video.analysisResults?.balance ?? 0.5) * 100 }
            
            let previousFrame = poseData[frameIndex - 1]
            if currentFrame.keypoints.count > 5 && previousFrame.keypoints.count > 5 &&
               currentFrame.confidence[5] > 0.8 && previousFrame.confidence[5] > 0.8 {
                
                let currentWrist = currentFrame.keypoints[5]
                let previousWrist = previousFrame.keypoints[5]
                let timeDiff = currentFrame.timestamp - previousFrame.timestamp
                
                if timeDiff > 0 {
                    let dx = currentWrist.x - previousWrist.x
                    let dy = currentWrist.y - previousWrist.y
                    let velocity = sqrt(dx*dx + dy*dy) / timeDiff
                    return max(20.0, min(120.0, velocity * 150.0))
                }
            }
        }
        
        return (video.analysisResults?.balance ?? 0.5) * 100
    }
    
    private func getLiveTempo() -> Double {
        return video.analysisResults?.tempo ?? 7.2
    }
    
    private func getLiveSwingPathDeviation() -> Double {
        return video.analysisResults?.swingPathDeviation ?? 0.0
    }
    
    private func getLiveSwingPathDescription() -> String {
        let deviation = getLiveSwingPathDeviation()
        if abs(deviation) < 2.0 {
            return "On Plane"
        } else if deviation < 0 {
            return "Inside-Out"
        } else {
            return "Outside-In"
        }
    }
}

// MARK: - Supporting Views

enum MetricStatus {
    case excellent, good, okay, needsImprovement
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .mint
        case .okay: return .yellow
        case .needsImprovement: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .okay: return "minus.circle"
        case .needsImprovement: return "exclamationmark.triangle"
        }
    }
}

struct MetricDetailCard: View {
    let title: String
    let value: String
    let unit: String
    let targetRange: String
    let status: MetricStatus
    let description: String
    let isClickable: Bool
    
    init(title: String, value: String, unit: String, targetRange: String, status: MetricStatus, description: String, isClickable: Bool = false) {
        self.title = title
        self.value = value
        self.unit = unit
        self.targetRange = targetRange
        self.status = status
        self.description = description
        self.isClickable = isClickable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(status.color)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: status.icon)
                        .font(.system(size: 20))
                        .foregroundColor(status.color)
                    
                    Text("Target: \(targetRange)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                
                if isClickable {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

enum ImprovementPriority {
    case high, medium, maintain
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .maintain: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .maintain: return "checkmark.circle.fill"
        }
    }
    
    var label: String {
        switch self {
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .maintain: return "Maintain"
        }
    }
}

struct ImprovementCard: View {
    let priority: ImprovementPriority
    let title: String
    let description: String
    let actionable: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: priority.icon)
                .font(.system(size: 20))
                .foregroundColor(priority.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(priority.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priority.color.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if actionable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

enum ContentType {
    case video, analysis, tracking
    
    var backgroundColor: Color {
        switch self {
        case .video: return .blue.opacity(0.1)
        case .analysis: return .purple.opacity(0.1)
        case .tracking: return .green.opacity(0.1)
        }
    }
}

struct RecommendedContentCard: View {
    let icon: String
    let title: String
    let description: String
    let duration: String
    let type: ContentType
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(type.backgroundColor)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !duration.isEmpty {
                        Text(duration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

struct ActionPlanCard: View {
    let week: String
    let focus: String
    let description: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Circle()
                    .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if !isActive {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(week)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isActive ? .blue : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background((isActive ? Color.blue : Color.gray).opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(focus)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isActive ? .primary : .secondary)
                    
                    Spacer()
                }
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(isActive ? 1.0 : 0.7)
        .contentShape(Rectangle())
    }
}
