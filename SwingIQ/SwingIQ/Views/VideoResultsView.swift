//
//  VideoResultsView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVKit

struct VideoResultsView: View {
    let video: ProcessingVideo
    // MediaPipe skeleton overlay is always enabled
    private let showPoseOverlay = true
    private let showSkeleton = true
    @State private var showKeypoints = true
    @State private var currentFrameIndex = 0
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Video player with overlay
            videoPlayerSection
            
            // Controls and toggles
            controlsSection
            
            // Analysis results
            if let results = video.analysisResults {
                analysisResultsSection(results)
            }
        }
        .navigationTitle("Swing Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
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
            } else {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        ProgressView("Loading video...")
                            .foregroundColor(.white)
                    )
            }
            
            // MediaPipe pose overlay - always visible
            if let poseData = video.poseData {
                PoseVideoOverlay(
                    poseData: poseData,
                    currentFrameIndex: currentFrameIndex,
                    showSkeleton: showSkeleton,
                    showKeypoints: showKeypoints
                )
            }
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Overlay toggles
            overlayToggles
            
            // Playback controls
            playbackControls
            
            // Frame scrubber
            if let poseData = video.poseData, !poseData.isEmpty {
                frameScrubber(poseData: poseData)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var overlayToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MediaPipe Visualization")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.green)
                    Text("Skeleton - Always Enabled")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Toggle("Show Keypoints", isOn: $showKeypoints)
                        .toggleStyle(SwitchToggleStyle())
                }
            }
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 20) {
            Button(action: {
                player?.seek(to: .zero)
                currentFrameIndex = 0
            }) {
                Image(systemName: "backward.end")
                    .font(.title2)
            }
            
            Button(action: {
                if isPlaying {
                    player?.pause()
                } else {
                    player?.play()
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
            }
            
            Button(action: {
                if let duration = player?.currentItem?.duration {
                    player?.seek(to: duration)
                    if let poseData = video.poseData {
                        currentFrameIndex = max(0, poseData.count - 1)
                    }
                }
            }) {
                Image(systemName: "forward.end")
                    .font(.title2)
            }
        }
    }
    
    private func frameScrubber(poseData: [PoseFrameData]) -> some View {
        VStack(spacing: 8) {
            Text("Frame: \(currentFrameIndex + 1) / \(poseData.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Slider(
                value: Binding(
                    get: { Double(currentFrameIndex) },
                    set: { newValue in
                        let frameIndex = Int(newValue)
                        currentFrameIndex = max(0, min(frameIndex, poseData.count - 1))
                        seekToFrame(frameIndex)
                    }
                ),
                in: 0...Double(max(0, poseData.count - 1)),
                step: 1
            )
        }
    }
    
    // MARK: - Analysis Results Section
    
    private func analysisResultsSection(_ results: SwingAnalysisResults) -> some View {
        VStack(spacing: 16) {
            // Overall score
            overallScoreCard(results.overallScore)
            
            // Metrics grid
            metricsGrid(results)
            
            // Recommendations
            recommendationsSection(results.recommendations)
        }
        .padding()
    }
    
    private func overallScoreCard(_ score: Double) -> some View {
        VStack(spacing: 8) {
            Text("Overall Score")
                .font(.headline)
            
            Text("\(Int(score))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor(score))
            
            Text("out of 100")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func metricsGrid(_ results: SwingAnalysisResults) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(title: "Swing Path", value: results.swingPathDescription, color: .indigo)
            MetricCard(title: "Tempo", value: String(format: "%.1fs", results.tempo), color: .orange)
            MetricCard(title: "Balance", value: String(format: "%.1f", results.balance * 10), color: .purple)
        }
    }
    
    private func recommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enhanced AI Analysis Section
            if let enhancedAnalysis = video.enhancedAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                        Text("AI Analysis")
                            .font(.headline)
                        Spacer()
                        Text("Powered by Gemini")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let feedback = enhancedAnalysis.geminiFeedback {
                        Text(feedback)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if !enhancedAnalysis.geminiImprovements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Improvements")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(enhancedAnalysis.geminiImprovements.enumerated()), id: \.offset) { index, improvement in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    Text(improvement)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
                
                // YouTube Recommendations
                if !enhancedAnalysis.youtubeRecommendations.isEmpty {
                    YouTubeRecommendationsView(recommendations: enhancedAnalysis.youtubeRecommendations)
                }
            }
            
            // Basic Recommendations Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Basic Analysis")
                    .font(.headline)
                
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                            .frame(width: 16)
                        
                        Text(recommendation)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        player = AVPlayer(url: video.url)
        
        // Set up periodic time observer to sync pose overlay
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0/30.0, preferredTimescale: 600), queue: .main) { time in
            self.updateCurrentFrame(for: time)
        }
    }
    
    private func updateCurrentFrame(for time: CMTime) {
        guard let poseData = video.poseData else { return }
        
        let currentTime = time.seconds
        
        // Find the closest frame index for the current time
        let frameIndex = poseData.enumerated().min { abs($0.element.timestamp - currentTime) < abs($1.element.timestamp - currentTime) }?.offset ?? 0
        
        currentFrameIndex = max(0, min(frameIndex, poseData.count - 1))
    }
    
    private func seekToFrame(_ frameIndex: Int) {
        guard let poseData = video.poseData,
              frameIndex < poseData.count else { return }
        
        let timestamp = poseData[frameIndex].timestamp
        let time = CMTime(seconds: timestamp, preferredTimescale: 600)
        player?.seek(to: time)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - Pose Video Overlay

struct PoseVideoOverlay: View {
    let poseData: [PoseFrameData]
    let currentFrameIndex: Int
    let showSkeleton: Bool
    let showKeypoints: Bool
    
    var body: some View {
        Canvas { context, size in
            guard currentFrameIndex < poseData.count else { return }
            
            let currentFrame = poseData[currentFrameIndex]
            
            // Draw keypoints
            if showKeypoints {
                for keypoint in currentFrame.keypoints {
                    let point = CGPoint(
                        x: keypoint.x * size.width,
                        y: keypoint.y * size.height
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
            
            // Draw skeleton connections
            if showSkeleton && currentFrame.keypoints.count >= 17 {
                drawSkeleton(context: context, size: size, keypoints: currentFrame.keypoints)
            }
        }
    }
    
    private func drawSkeleton(context: GraphicsContext, size: CGSize, keypoints: [CGPoint]) {
        // Define pose connections (MediaPipe pose landmark connections)
        let connections: [(Int, Int)] = [
            // Face
            (0, 1), (1, 2), (2, 3), (3, 7),
            (0, 4), (4, 5), (5, 6), (6, 8),
            
            // Torso
            (9, 10), (11, 12),
            (11, 13), (13, 15),
            (12, 14), (14, 16),
            (11, 23), (12, 24), (23, 24),
            
            // Legs
            (23, 25), (25, 27), (27, 29), (29, 31),
            (24, 26), (26, 28), (28, 30), (30, 32)
        ]
        
        for (startIdx, endIdx) in connections {
            guard startIdx < keypoints.count && endIdx < keypoints.count else { continue }
            
            let startPoint = CGPoint(
                x: keypoints[startIdx].x * size.width,
                y: keypoints[startIdx].y * size.height
            )
            let endPoint = CGPoint(
                x: keypoints[endIdx].x * size.width,
                y: keypoints[endIdx].y * size.height
            )
            
            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            context.stroke(path, with: .color(.white), lineWidth: 2)
        }
    }
}

// MARK: - Video Picker

struct VideoPickerView: UIViewControllerRepresentable {
    let onVideoSelected: (URL) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoSelected(videoURL)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct VideoResultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoResultsView(video: ProcessingVideo(
                url: URL(string: "file://test.mp4")!,
                name: "Test Swing",
                dateAdded: Date(),
                progress: 1.0,
                status: .completed,
                analysisResults: SwingAnalysisResults(
                    tempo: 2.1,
                    balance: 0.85,
                    swingPathDeviation: 3.2,
                    swingPhase: "Full Swing",
                    overallScore: 78.5,
                    recommendations: ["Focus on maintaining balance through impact"]
                )
            ))
        }
    }
}
