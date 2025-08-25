//
//  SwingAnalysisResultsView.swift
//  SwingIQ
//
//  Created by Amp on 7/23/25.
//

import SwiftUI
import AVKit
import SceneKit

struct SwingAnalysisResultsView: View {
    let video: ProcessingVideo
    @Environment(\.presentationMode) var presentationMode
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1.0
    @State private var playbackSpeed: Float = 1.0
    @State private var selectedView: AnalysisViewType = .video
    
    // MediaPipe is always enabled - no toggle needed
    private let showSkeletonOverlay = true
    @State private var showSwingPath = true
    @State private var showSwingPlane = false
    @State private var showZones = true
    
    // UI state
    @State private var selectedTab: AnalysisTab = .overview
    @State private var showingControls = true
    
    private let playbackSpeeds: [Float] = [0.25, 0.5, 1.0, 2.0]
    
    enum AnalysisViewType: String, CaseIterable {
        case video = "Video Analysis"
        case threeDView = "3D View"
        
        var icon: String {
            switch self {
            case .video: return "play.rectangle"
            case .threeDView: return "cube"
            }
        }
    }
    
    enum AnalysisTab: String, CaseIterable {
        case overview = "Overview"
        case metrics = "Metrics"
        case breakdown = "Breakdown"
        case recommendations = "Tips"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar"
            case .metrics: return "speedometer"
            case .breakdown: return "list.bullet"
            case .recommendations: return "lightbulb"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // View mode selector
                viewModeSelector
                
                // Main content area
                mainContentArea
                
                // Bottom controls and analysis
                if showingControls {
                    bottomControlsSection
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingControls.toggle()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Swing Analysis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                if let results = video.analysisResults {
                    HStack(spacing: 8) {
                        Text("Score: \(safeInt(results.overallScore))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(scoreColor(results.overallScore))
                        
                        Circle()
                            .fill(scoreColor(results.overallScore))
                            .frame(width: 6, height: 6)
                        
                        Text(getScoreLabel(results.overallScore))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(scoreColor(results.overallScore))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - View Mode Selector
    
    private var viewModeSelector: some View {
        HStack(spacing: 12) {
            ForEach(AnalysisViewType.allCases, id: \.self) { viewType in
                Button(action: {
                    selectedView = viewType
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewType.icon)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(viewType.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedView == viewType ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedView == viewType ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
    }
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        ZStack {
            switch selectedView {
            case .video:
                videoAnalysisView
            case .threeDView:
                threeDAnalysisView
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Video Analysis View
    
    private var videoAnalysisView: some View {
        ZStack {
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                        isPlaying = (status == .playing)
                    }
            }
            
            // Swing analysis overlays
            swingAnalysisOverlays
            
            // Play/pause overlay when controls are hidden
            if !showingControls {
                playPauseOverlay
            }
        }
    }
    
    // MARK: - 3D Analysis View
    
    private var threeDAnalysisView: some View {
        ZStack {
            Color.black
            
            if let poseData = video.poseData {
                SwingPose3DView(
                    poseData: poseData,
                    currentTime: $currentTime,
                    duration: duration
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "cube")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("3D View Unavailable")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Pose data not available for this video")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Swing Analysis Overlays
    
    private var swingAnalysisOverlays: some View {
        GeometryReader { geometry in
            ZStack {

                
                // MediaPipe skeleton overlay - always visible
                if let poseData = video.poseData {
                    MediaPipeOverlay(
                        poseData: poseData,
                        currentTime: currentTime,
                        viewSize: geometry.size,
                        videoSize: video.videoSize
                    )
                }
            }
        }
    }
    
    // MARK: - Play/Pause Overlay
    
    private var playPauseOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 30) {
                Button(action: cyclePlaybackSpeed) {
                    Text("\(playbackSpeed == 1.0 ? "1x" : String(format: "%.2gx", playbackSpeed))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                }
                
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.7)).frame(width: 60, height: 60))
                }
                
                Button(action: stepFrame) {
                    Image(systemName: "forward.frame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Bottom Controls Section
    
    private var bottomControlsSection: some View {
        VStack(spacing: 0) {
            // Video controls (only show for video view)
            if selectedView == .video {
                videoControlsSection
            }
            
            // Overlay toggles
            overlayToggleSection
            
            // Analysis tabs
            analysisTabsSection
        }
        .background(Color.black.opacity(0.95))
    }
    
    // MARK: - Video Controls Section
    
    private var videoControlsSection: some View {
        VStack(spacing: 12) {
            // Time scrubber
            VStack(spacing: 6) {
                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: $currentTime, in: 0...max(1.0, duration.isFinite ? duration : 1.0)) { editing in
                    if !editing {
                        seekToTime(currentTime)
                    }
                }
                .accentColor(Color(hex: "00B04F"))
            }
            
            // Playback controls
            HStack(spacing: 20) {
                // Speed controls
                HStack(spacing: 8) {
                    ForEach(playbackSpeeds, id: \.self) { speed in
                        Button(action: {
                            setPlaybackSpeed(speed)
                        }) {
                            Text(speed == 1.0 ? "1x" : String(format: "%.2gx", speed))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(playbackSpeed == speed ? Color(hex: "00B04F") : .white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(playbackSpeed == speed ? Color(hex: "00B04F").opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Main controls
                HStack(spacing: 16) {
                    Button(action: seekToBeginning) {
                        Image(systemName: "backward.end.fill")
                            .foregroundColor(.white)
                    }
                    
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: seekToEnd) {
                        Image(systemName: "forward.end.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Overlay Toggle Section
    
    private var overlayToggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Analysis Overlays")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AnalysisToggle(
                    title: "Swing Path",
                    icon: "scribble.variable",
                    isOn: $showSwingPath,
                    color: Color(hex: "FF6B35")
                )
                
                AnalysisToggle(
                    title: "Swing Zones",
                    icon: "target",
                    isOn: $showZones,
                    color: Color(hex: "8E44AD")
                )
                
                AnalysisToggle(
                    title: "Swing Plane",
                    icon: "line.diagonal",
                    isOn: $showSwingPlane,
                    color: Color(hex: "4A90E2")
                )
                
                // MediaPipe skeleton is always enabled - toggle removed
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "1B8B3A"))
                        
                        Text("Skeleton")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Always On")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "1B8B3A"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "1B8B3A").opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Analysis Tabs Section
    
    private var analysisTabsSection: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                ForEach(AnalysisTab.allCases, id: \.self) { tab in
                    AnalysisTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            
            // Tab content
            Group {
                switch selectedTab {
                case .overview:
                    overviewTabContent
                case .metrics:
                    metricsTabContent
                case .breakdown:
                    breakdownTabContent
                case .recommendations:
                    recommendationsTabContent
                }
            }
            .frame(minHeight: 200, maxHeight: 250)
        }
    }
    
    // MARK: - Tab Contents
    
    private var overviewTabContent: some View {
        ScrollView {
            if let results = video.analysisResults {
                VStack(spacing: 20) {
                    // Overall score card
                    overallScoreCard(results: results)
                    
                    // Key metrics grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        CompactMetricCard(
                            title: "Tempo",
                            value: String(format: "%.1f", results.tempo),
                            unit: "s",
                            color: Color(hex: "FF6B35")
                        )
                        
                        CompactMetricCard(
                            title: "Path",
                            value: String(format: "%.1f", results.swingPathDeviation),
                            unit: "°",
                            color: Color(hex: "4A90E2")
                        )
                        
                        CompactMetricCard(
                            title: "Balance",
                            value: "\(safeInt(results.balance * 100))",
                            unit: "%",
                            color: Color(hex: "1B8B3A")
                        )
                    }
                    
                    // Swing path analysis
                    swingPathAnalysisCard(results: results)
                }
                .padding()
            }
        }
    }
    
    private var metricsTabContent: some View {
        ScrollView {
            if let results = video.analysisResults {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DetailedMetricCard(
                        title: "Swing Path",
                        value: String(format: "%.1f", results.swingPathDeviation),
                        unit: "°",
                        color: Color(hex: "FF6B35"),
                        trend: .neutral,
                        benchmark: "Ideal: ±2°"
                    )
                    
                    DetailedMetricCard(
                        title: "Balance",
                        value: "\(safeInt(results.balance * 100))",
                        unit: "%",
                        color: Color(hex: "9C27B0"),
                        trend: .up,
                        benchmark: "Target: >80%"
                    )
                    
                    DetailedMetricCard(
                        title: "Tempo",
                        value: String(format: "%.1f", results.tempo.isFinite ? results.tempo : 0.0),
                        unit: ":1",
                        color: Color(hex: "8E44AD"),
                        trend: .down,
                        benchmark: "Ideal: 3:1"
                    )
                    
                    DetailedMetricCard(
                        title: "Balance",
                        value: "\(safeInt(results.balance * 100))",
                        unit: "%",
                        color: Color(hex: "1B8B3A"),
                        trend: .up,
                        benchmark: "Target: >85%"
                    )
                }
                .padding()
            }
        }
    }
    
    private var breakdownTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let results = video.analysisResults {
                    // Swing phases breakdown
                    swingPhasesBreakdown
                    
                    // Zone analysis
                    zoneAnalysisBreakdown(results: results)
                }
            }
            .padding()
        }
    }
    
    private var recommendationsTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Gemini Analysis Section
                if let enhancedAnalysis = video.enhancedAnalysis {
                    geminiAnalysisSection(enhancedAnalysis)
                }
                
                // YouTube Recommendations Section
                if let enhancedAnalysis = video.enhancedAnalysis, !enhancedAnalysis.youtubeRecommendations.isEmpty {
                    YouTubeRecommendationsView(recommendations: enhancedAnalysis.youtubeRecommendations)
                }
                
                // Basic Recommendations Section
                if let results = video.analysisResults {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text("Basic Analysis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        ForEach(results.recommendations, id: \.self) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                        }
                    }
                } else {
                    Text("No recommendations available")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
        }
    }
    
    private func geminiAnalysisSection(_ analysis: EnhancedAnalysisResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Color(hex: "4A90E2"))
                
                Text("AI Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Powered by Gemini")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if let feedback = analysis.geminiFeedback {
                Text(feedback)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            
            if !analysis.geminiImprovements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Improvements")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ForEach(Array(analysis.geminiImprovements.enumerated()), id: \.offset) { index, improvement in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "FF6B35"))
                            
                            Text(improvement)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            if !analysis.geminiTechnicalTips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technical Tips")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ForEach(Array(analysis.geminiTechnicalTips.enumerated()), id: \.offset) { index, tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "1B8B3A"))
                                .font(.system(size: 14))
                            
                            Text(tip)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private func overallScoreCard(results: SwingAnalysisResults) -> some View {
        NavigationLink(destination: SwingAnalysisDashboard(analyses: [])) {
            VStack(spacing: 12) {
                Text("Overall Swing Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Text("\(safeInt(results.overallScore))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor(results.overallScore))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getScoreLabel(results.overallScore))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(scoreColor(results.overallScore))
                        
                        Text("Out of 100")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [scoreColor(results.overallScore).opacity(0.2), scoreColor(results.overallScore).opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(scoreColor(results.overallScore).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func swingPathAnalysisCard(results: SwingAnalysisResults) -> some View {
        NavigationLink(destination: SwingPathDashboard(analyses: [])) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "scribble.variable")
                        .foregroundColor(Color(hex: "FF6B35"))
                    
                    Text("Swing Path Analysis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getSwingPathDescription(results.swingPathDeviation))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(getSwingPathColor(results.swingPathDeviation))
                    
                    Text("\(safeInt(abs(results.swingPathDeviation)))° \(results.swingPathDeviation < 0 ? "inside" : "outside")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                SwingPathVisualization(deviation: results.swingPathDeviation)
            }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var swingPhasesBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swing Phases")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            let phases = [
                ("Address", "Good posture", Color(hex: "1B8B3A")),
                ("Takeaway", "Smooth start", Color(hex: "1B8B3A")),
                ("Backswing", "Full shoulder turn", Color(hex: "FF6B35")),
                ("Transition", "Good sequence", Color(hex: "1B8B3A")),
                ("Downswing", "Strong acceleration", Color(hex: "1B8B3A")),
                ("Impact", "Solid contact", Color(hex: "4A90E2")),
                ("Follow-through", "Complete finish", Color(hex: "1B8B3A"))
            ]
            
            ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                HStack(spacing: 12) {
                    Circle()
                        .fill(phase.2)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.0)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(phase.1)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func zoneAnalysisBreakdown(results: SwingAnalysisResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(Color(hex: "8E44AD"))
                
                Text("Zone Analysis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                zoneAnalysisRow(
                    title: "Impact Zone",
                    status: "In Zone",
                    percentage: 85,
                    color: Color(hex: "1B8B3A")
                )
                
                zoneAnalysisRow(
                    title: "Swing Plane Zone",
                    status: "Mostly On Plane",
                    percentage: 78,
                    color: Color(hex: "FF6B35")
                )
                
                zoneAnalysisRow(
                    title: "Tempo Zone",
                    status: "Good Rhythm",
                    percentage: 92,
                    color: Color(hex: "4A90E2")
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func zoneAnalysisRow(title: String, status: String, percentage: Int, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text("\(percentage)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Helper Methods
    
    private func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(value)
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: video.url)
        
        // Set up time observers
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            let timeSeconds = time.seconds
            currentTime = timeSeconds.isFinite ? timeSeconds : 0
        }
        
        // Get duration
        if let duration = player?.currentItem?.duration {
            let durationSeconds = duration.seconds
            self.duration = durationSeconds.isFinite && durationSeconds > 0 ? durationSeconds : 1.0
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.rate = playbackSpeed
            player?.play()
        }
    }
    
    private func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }
    
    private func cyclePlaybackSpeed() {
        if let currentIndex = playbackSpeeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % playbackSpeeds.count
            setPlaybackSpeed(playbackSpeeds[nextIndex])
        }
    }
    
    private func seekToTime(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func seekToBeginning() {
        seekToTime(0)
    }
    
    private func seekToEnd() {
        seekToTime(duration)
    }
    
    private func stepFrame() {
        // Step forward by 1/30th of a second (assuming 30fps)
        let frameTime = 1.0 / 30.0
        let newTime = min(currentTime + frameTime, duration)
        seekToTime(newTime)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite else { return "0:00" }
        let safeTime = max(0, time)
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 85...100: return Color(hex: "1B8B3A")
        case 70..<85: return Color(hex: "FF6B35")
        case 50..<70: return Color(hex: "8E44AD")
        default: return Color.red
        }
    }
    
    private func getScoreLabel(_ score: Double) -> String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Needs Work"
        }
    }
    
    private func getSwingPathDescription(_ deviation: Double) -> String {
        if abs(deviation) < 2.0 {
            return "On Plane"
        } else if deviation < 0 {
            return "Inside-Out"
        } else {
            return "Outside-In"
        }
    }
    
    private func getSwingPathColor(_ deviation: Double) -> Color {
        if abs(deviation) < 2.0 {
            return Color(hex: "1B8B3A")
        } else if abs(deviation) < 5.0 {
            return Color(hex: "FF6B35")
        } else {
            return Color.red
        }
    }
}

// MARK: - Supporting Views and Components

struct AnalysisToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isOn ? color : .white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isOn ? .white : .white.opacity(0.6))
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .scaleEffect(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? color.opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct AnalysisTabButton: View {
    let tab: SwingAnalysisResultsView.AnalysisTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(hex: "00B04F") : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(hex: "00B04F").opacity(0.2) : Color.clear)
        }
    }
}

struct CompactMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DetailedMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let trend: TrendDirection
    let benchmark: String
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .neutral: return "minus.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return Color(hex: "1B8B3A")
            case .down: return Color.red
            case .neutral: return Color.gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.system(size: 10))
                    .foregroundColor(trend.color)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(benchmark)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let recommendation: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(recommendation)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SwingPathVisualization: View {
    let deviation: Double
    
    var body: some View {
        ZStack {
            // Target line
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 60, height: 4)
            
            // Actual path
            RoundedRectangle(cornerRadius: 2)
                .fill(getSwingPathColor(deviation))
                .frame(width: 60, height: 4)
                .rotationEffect(.degrees(deviation * 2)) // Exaggerate for visibility
        }
        .frame(width: 80, height: 40)
    }
    
    private func getSwingPathColor(_ deviation: Double) -> Color {
        if abs(deviation) < 2.0 {
            return Color(hex: "1B8B3A")
        } else if abs(deviation) < 5.0 {
            return Color(hex: "FF6B35")
        } else {
            return Color.red
        }
    }
}


