//
//  SwingAnalysisFullScreenViewRefactored.swift
//  SwingIQ
//
//  Refactored full-screen swing analysis with separated components
//

import SwiftUI
import AVKit
import UIKit
import Combine

struct SwingAnalysisFullScreenViewRefactored: View {
    let video: ProcessingVideo
    @Environment(\.dismiss) private var dismiss
    
    var onNavigateToHome: (() -> Void)?
    
    // Video player state
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1.0
    @State private var playbackSpeed: Float = 1.0
    
    @State private var videoRect: CGRect = .zero
    @State private var showingControls = true
    @State private var controlsTimer: Timer?
    @State private var timeObserver: Any?
    @State private var statusObserver: AnyCancellable?
    @State private var scrollIndicatorOffset: CGFloat = 0
    @State private var showScrollIndicator = true
    
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
                    handleRefresh()
                }
                .gesture(swipeGesture)
                .onReceive(videoEndNotification) { _ in
                    withAnimation(.easeInOut(duration: 1.0)) {
                        proxy.scrollTo("analysisSection", anchor: .top)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: setupView)
    }
    
    // MARK: - Video Player Section
    
    private var videoPlayerSection: some View {
        ZStack {
            Color.black
            
            // Unified Video Player
            UnifiedVideoPlayerComponent(
                url: video.url,
                configuration: .fullscreen,
                onVideoRectChange: { rect in
                    self.videoRect = rect
                },
                onTimeChange: { time in
                    self.currentTime = time
                },
                onPlaybackStateChange: { playing in
                    self.isPlaying = playing
                }
            )
            
            // MediaPipe skeleton overlay
            if let poseData = video.poseData, !poseData.isEmpty {
                GeometryReader { geo in
                    MediaPipeOverlay(
                        poseData: poseData,
                        currentTime: currentTime,
                        viewSize: geo.size,
                        videoSize: video.videoSize,
                        isMirrored: video.isMirrored ?? false
                    )
                }
            } else {
                missingPoseDataView
            }
            
            // Live data display
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Spacer()
                        LiveDataPanel(
                            poseData: video.poseData,
                            currentTime: currentTime
                        )
                        .padding(.top, max(geometry.safeAreaInsets.top + 60, 80))
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .allowsHitTesting(false)
            
            // Tap gesture area
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture(perform: toggleControlsVisibility)
                .zIndex(-1)
            
            // Video controls overlay
            videoControlsOverlay
                .opacity(showingControls ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showingControls)
                .allowsHitTesting(showingControls)
                .zIndex(100)
            
            // Scroll indicator overlay
            scrollIndicatorOverlay
        }
    }
    
    // MARK: - Video Controls Overlay
    
    private var videoControlsOverlay: some View {
        VStack {
            Spacer()
            
            VideoPlayerControls(
                currentTime: $currentTime,
                duration: $duration,
                playbackSpeed: $playbackSpeed,
                isPlaying: $isPlaying,
                showingControls: $showingControls,
                onSeek: seekToTime,
                onTogglePlayback: togglePlayback,
                onCycleSpeed: cyclePlaybackSpeed
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Analysis Results Section
    
    private var analysisResultsSection: some View {
        VStack(spacing: 24) {
            // Analysis Summary Card
            AnalysisSummaryCard { 
                // Navigate to dashboard
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            // Key Metrics Section
            KeyMetricsSection(
                liveBalance: getLiveBalance(),
                liveTempo: getLiveTempo(),
                liveSwingPathDescription: getLiveSwingPathDescription(),
                onNavigateToBalance: { },
                onNavigateToTempo: { },
                onNavigateToSwingPath: { },
                onNavigateToHipShoulder: { }
            )
            .padding(.horizontal, 16)
            
            // Areas for Improvement
            ImprovementSection(
                enhancedAnalysis: nil, // TODO: Convert EnhancedAnalysisResults to SwingAnalysis if needed
                onNavigateToAnalysis: { },
                onNavigateToSpeed: { },
                onNavigateToTempo: { }
            )
            .padding(.horizontal, 16)
            
            // Recommended Content
            RecommendedContentSection(
                enhancedAnalysis: nil, // TODO: Convert EnhancedAnalysisResults to SwingAnalysis if needed
                onNavigateToSpeed: { },
                onNavigateToTempo: { },
                onNavigateToAnalysis: { },
                onNavigateToProgress: { }
            )
            .padding(.horizontal, 16)
            
            // Action Plan
            ActionPlanSection(
                onNavigateToSpeed: { },
                onNavigateToTempo: { },
                onNavigateToBalance: { },
                onNavigateToProgress: { }
            )
            .padding(.horizontal, 16)
            
            // Share Button
            shareButton
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
        }
    }
    
    // MARK: - Supporting Views
    
    private var missingPoseDataView: some View {
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
        .allowsHitTesting(false)
    }
    
    private var shareButton: some View {
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
    
    private var scrollIndicatorOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Analysis")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .offset(y: scrollIndicatorOffset)
                .opacity(showScrollIndicator ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: showScrollIndicator)
            }
            .padding(.bottom, 100)
            .padding(.trailing, 30)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Computed Properties
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                if gesture.translation.height > 80 && gesture.startLocation.y < 200 {
                    handleRefresh()
                }
            }
    }
    
    private var videoEndNotification: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
    }
    
    // MARK: - Action Methods
    
    private func handleRefresh() {
        if let onNavigateToHome = onNavigateToHome {
            onNavigateToHome()
        } else {
            dismiss()
        }
    }
    
    // Removed autoScrollToAnalysis function - inlined for simplicity
    
    private func setupView() {
        startFloatingAnimation()
        startScrollIndicatorTimer()
    }
    
    private func toggleControlsVisibility() {
        showingControls.toggle()
    }
    
    private func seekToTime(_ time: Double) {
        // TODO: Implement seek functionality
    }
    
    private func togglePlayback() {
        // TODO: Implement playback toggle
    }
    
    private func cyclePlaybackSpeed() {
        // TODO: Implement speed cycling
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
    
    // MARK: - Live Data Helpers
    
    private func getLiveBalance() -> Double {
        return (video.analysisResults?.balance ?? 0.5) * 100
    }
    
    private func getLiveTempo() -> Double {
        return video.analysisResults?.tempo ?? 3.0
    }
    
    private func getLiveSwingPathDescription() -> String {
        let deviation = video.analysisResults?.swingPathDeviation ?? 0.0
        if abs(deviation) < 2.0 {
            return "On Plane"
        } else if deviation < 0 {
            return "Inside-Out"
        } else {
            return "Outside-In"
        }
    }
}
