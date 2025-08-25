//
//  EnhancedVideoResultsView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVKit

struct EnhancedVideoResultsView: View {
    let video: ProcessingVideo
    @Environment(\.presentationMode) var presentationMode
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var playbackSpeed: Float = 1.0
    @State private var currentFrameIndex = 0
    
    // Overlay toggles
    @State private var showSwingPath = false
    // MediaPipe skeleton is always enabled
    private let showSkeleton = true
    @State private var showKeyPositions = false
    @State private var showTempoMarkers = false
    
    // UI state
    @State private var showingOverlayControls = true
    @State private var selectedAnalysisTab = 0
    
    private let playbackSpeeds: [Float] = [0.25, 0.5, 1.0, 2.0, 4.0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Video player with overlays
                videoPlayerSection
                
                // Controls section
                if showingOverlayControls {
                    controlsSection
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            print("🎬 EnhancedVideoResultsView appeared for video: \(video.name)")
            print("🎬 Video has analysis results: \(video.analysisResults != nil)")
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingOverlayControls.toggle()
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
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Swing Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let results = video.analysisResults {
                    Text("Score: \(Int(results.overallScore))/100")
                        .font(.caption)
                        .foregroundColor(scoreColor(results.overallScore))
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
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.7))
    }
    
    // MARK: - Video Player Section
    
    private var videoPlayerSection: some View {
        ZStack {
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                        isPlaying = (status == .playing)
                    }
            }
            
            // Overlays
            overlaySection
            
            // Playback controls overlay
            if !showingOverlayControls {
                playbackControlsOverlay
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Overlay Section
    
    private var overlaySection: some View {
        GeometryReader { geometry in
            ZStack {
                // Swing path overlay
                if showSwingPath, let poseData = video.poseData {
                    SwingPathOverlay(poseData: poseData, currentFrame: currentFrameIndex)
                }
                
                // MediaPipe skeleton overlay - always visible
                if let poseData = video.poseData {
                    SkeletonOverlay(poseData: poseData, currentFrame: currentFrameIndex)
                }
                
                // Key positions overlay
                if showKeyPositions, let poseData = video.poseData {
                    KeyPositionsOverlay(poseData: poseData, currentFrame: currentFrameIndex)
                }
                
                // Tempo markers overlay
                if showTempoMarkers, let poseData = video.poseData {
                    TempoMarkersOverlay(poseData: poseData, currentFrame: currentFrameIndex)
                }
            }
        }
    }
    
    // MARK: - Playback Controls Overlay
    
    private var playbackControlsOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 30) {
                // Speed control
                Button(action: cyclePlaybackSpeed) {
                    Text("\(playbackSpeed == 1.0 ? "1x" : String(format: "%.2gx", playbackSpeed))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                }
                
                // Play/Pause
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // Frame by frame
                Button(action: stepFrame) {
                    Image(systemName: "forward.frame.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 0) {
            // Playback controls
            playbackControlsSection
            
            // Overlay toggles
            overlayControlsSection
            
            // Analysis tabs
            analysisTabsSection
        }
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Playback Controls Section
    
    private var playbackControlsSection: some View {
        VStack(spacing: 12) {
            // Time scrubber
            VStack(spacing: 4) {
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: $currentTime, in: 0...duration) { editing in
                    if !editing {
                        seekToTime(currentTime)
                    }
                }
                .accentColor(.blue)
            }
            
            // Control buttons
            HStack(spacing: 20) {
                // Speed controls
                HStack(spacing: 8) {
                    ForEach(playbackSpeeds, id: \.self) { speed in
                        Button(action: {
                            setPlaybackSpeed(speed)
                        }) {
                            Text(speed == 1.0 ? "1x" : String(format: "%.2gx", speed))
                                .font(.caption)
                                .fontWeight(playbackSpeed == speed ? .bold : .regular)
                                .foregroundColor(playbackSpeed == speed ? .blue : .white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(playbackSpeed == speed ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Playback controls
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
    }
    
    // MARK: - Overlay Controls Section
    
    private var overlayControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Overlays")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                OverlayToggle(
                    title: "Swing Path",
                    icon: "scribble.variable",
                    isOn: $showSwingPath,
                    color: .orange
                )
                
                // MediaPipe skeleton is always enabled - toggle removed
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Skeleton")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Always On")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                
                OverlayToggle(
                    title: "Key Positions",
                    icon: "location.circle",
                    isOn: $showKeyPositions,
                    color: .red
                )
                
                OverlayToggle(
                    title: "Tempo",
                    icon: "metronome",
                    isOn: $showTempoMarkers,
                    color: .purple
                )
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
                TabButton(title: "Metrics", isSelected: selectedAnalysisTab == 0) {
                    selectedAnalysisTab = 0
                }
                
                TabButton(title: "Breakdown", isSelected: selectedAnalysisTab == 1) {
                    selectedAnalysisTab = 1
                }
                
                TabButton(title: "Tips", isSelected: selectedAnalysisTab == 2) {
                    selectedAnalysisTab = 2
                }
            }
            
            // Tab content
            Group {
                switch selectedAnalysisTab {
                case 0:
                    metricsTabContent
                case 1:
                    breakdownTabContent
                case 2:
                    tipsTabContent
                default:
                    metricsTabContent
                }
            }
            .frame(height: 200)
        }
    }
    
    // MARK: - Tab Contents
    
    private var metricsTabContent: some View {
        ScrollView {
            if let results = video.analysisResults {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    NavigationLink(destination: SwingPathDashboard(analyses: [])) {
                        EnhancedMetricCard(
                            title: "Swing Path",
                            value: String(format: "%.1f°", results.swingPathDeviation),
                            color: .blue,
                            trend: .neutral
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TempoDashboard(analyses: [])) {
                        EnhancedMetricCard(
                            title: "Tempo",
                            value: String(format: "%.1fs", results.tempo),
                            color: .orange,
                            trend: .down
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: ProgressTrackingDashboard(analyses: [])) {
                        EnhancedMetricCard(
                            title: "Balance",
                            value: String(format: "%.1f/10", results.balance * 10),
                            color: .purple,
                            trend: .up
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
        }
    }
    
    private var breakdownTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let results = video.analysisResults {
                    SwingPhaseBreakdown(results: results)
                }
            }
            .padding()
        }
    }
    
    private var tipsTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Enhanced AI Analysis Section
                if let enhancedAnalysis = video.enhancedAnalysis {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text("AI Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("Powered by Gemini")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if let feedback = enhancedAnalysis.geminiFeedback {
                            Text(feedback)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if !enhancedAnalysis.geminiImprovements.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Improvements")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                ForEach(Array(enhancedAnalysis.geminiImprovements.enumerated()), id: \.offset) { index, improvement in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(index + 1).")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                        
                                        Text(improvement)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        if !enhancedAnalysis.geminiTechnicalTips.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Technical Tips")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                ForEach(enhancedAnalysis.geminiTechnicalTips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        
                                        Text(tip)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    // YouTube Recommendations
                    if !enhancedAnalysis.youtubeRecommendations.isEmpty {
                        YouTubeRecommendationsView(recommendations: enhancedAnalysis.youtubeRecommendations)
                    }
                }
                
                // Basic Recommendations Section
                if let results = video.analysisResults {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Basic Analysis")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(results.recommendations, id: \.self) { tip in
                            TipCard(tip: tip)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        player = AVPlayer(url: video.url)
        
        // Set up time observers
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
            updateCurrentFrame()
        }
        
        // Get duration
        if let duration = player?.currentItem?.duration {
            self.duration = duration.seconds
        }
    }
    
    private func updateCurrentFrame() {
        guard let poseData = video.poseData else { return }
        
        // Find closest frame index for current time
        let frameIndex = poseData.enumerated().min {
            abs($0.element.timestamp - currentTime) < abs($1.element.timestamp - currentTime)
        }?.offset ?? 0
        
        currentFrameIndex = max(0, min(frameIndex, poseData.count - 1))
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
        guard let poseData = video.poseData else { return }
        
        if currentFrameIndex < poseData.count - 1 {
            currentFrameIndex += 1
            let timestamp = poseData[currentFrameIndex].timestamp
            seekToTime(timestamp)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct OverlayToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(isOn ? color : .white.opacity(0.6))
                
                Text(title)
                    .font(.caption)
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

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        }
    }
}

struct EnhancedMetricCard: View {
    let title: String
    let value: String
    let color: Color
    let trend: TrendDirection
    
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
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SwingPhaseBreakdown: View {
    let results: SwingAnalysisResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swing Phase Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            // Placeholder phase data
            let phases = [
                ("Setup", "Good posture", Color.green),
                ("Backswing", "Excellent turn", Color.green),
                ("Downswing", "Good acceleration", Color.orange),
                ("Impact", "Solid contact", Color.green),
                ("Follow-through", "Complete finish", Color.green)
            ]
            
            ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                HStack {
                    Circle()
                        .fill(phase.2)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.0)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(phase.1)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct TipCard: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(tip)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Overlay Views (Placeholder implementations)

struct SwingPathOverlay: View {
    let poseData: [PoseFrameData]
    let currentFrame: Int
    
    var body: some View {
        Canvas { context, size in
            // Draw swing path as connected lines
            var path = Path()
            
            for i in 0..<min(currentFrame, poseData.count) {
                let frame = poseData[i]
                if frame.keypoints.count > 15 { // Right wrist
                    let point = CGPoint(
                        x: frame.keypoints[15].x * size.width,
                        y: frame.keypoints[15].y * size.height
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            
            context.stroke(path, with: .color(.orange), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

struct SkeletonOverlay: View {
    let poseData: [PoseFrameData]
    let currentFrame: Int
    
    var body: some View {
        Canvas { context, size in
            guard currentFrame < poseData.count else { return }
            let frame = poseData[currentFrame]
            
            // Draw skeleton connections (simplified)
            let connections: [(Int, Int)] = [
                (11, 12), (11, 13), (13, 15), (12, 14), (14, 16), // Arms
                (11, 23), (12, 24), (23, 24), // Torso
                (23, 25), (25, 27), (24, 26), (26, 28) // Legs
            ]
            
            for (start, end) in connections {
                if start < frame.keypoints.count && end < frame.keypoints.count {
                    let startPoint = CGPoint(
                        x: frame.keypoints[start].x * size.width,
                        y: frame.keypoints[start].y * size.height
                    )
                    let endPoint = CGPoint(
                        x: frame.keypoints[end].x * size.width,
                        y: frame.keypoints[end].y * size.height
                    )
                    
                    var path = Path()
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                    
                    context.stroke(path, with: .color(.green), lineWidth: 2)
                }
            }
        }
    }
}

struct KeyPositionsOverlay: View {
    let poseData: [PoseFrameData]
    let currentFrame: Int
    
    var body: some View {
        Canvas { context, size in
            guard currentFrame < poseData.count else { return }
            let frame = poseData[currentFrame]
            
            // Draw key position markers
            let keyPoints = [11, 12, 13, 14, 15, 16] // Shoulders, elbows, wrists
            
            for pointIndex in keyPoints {
                if pointIndex < frame.keypoints.count {
                    let point = CGPoint(
                        x: frame.keypoints[pointIndex].x * size.width,
                        y: frame.keypoints[pointIndex].y * size.height
                    )
                    
                    context.fill(
                        Path(ellipseIn: CGRect(
                            origin: CGPoint(x: point.x - 4, y: point.y - 4),
                            size: CGSize(width: 8, height: 8)
                        )),
                        with: .color(.red)
                    )
                }
            }
        }
    }
}

struct TempoMarkersOverlay: View {
    let poseData: [PoseFrameData]
    let currentFrame: Int
    
    var body: some View {
        Canvas { context, size in
            // Draw tempo beat markers at regular intervals
            let beatInterval = poseData.count / 4 // 4 beats for a swing
            
            for i in stride(from: 0, to: poseData.count, by: beatInterval) {
                if i <= currentFrame {
                    let x = Double(i) / Double(poseData.count) * size.width
                    let rect = CGRect(x: x - 1, y: 0, width: 2, height: size.height)
                    
                    context.fill(Path(rect), with: .color(.purple.opacity(0.6)))
                }
            }
        }
    }
}

// MARK: - Preview

struct EnhancedVideoResultsView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedVideoResultsView(video: ProcessingVideo(
            url: URL(string: "file://test.mp4")!,
            name: "Test Swing",
            dateAdded: Date(),
            progress: 1.0,
            status: .completed,
            analysisResults: SwingAnalysisResults(
                tempo: 2.1,
                balance: 0.85,
                swingPathDeviation: -1.2,
                swingPhase: "Full Swing",
                overallScore: 78.5,
                recommendations: ["Focus on maintaining balance through impact"]
            )
        ))
    }
}
