//
//  SwingAnalysisResultsViewRedesigned.swift
//  SwingIQ
//
//  Simple video-centric swing analysis view
//

import SwiftUI
import AVKit
import SceneKit
import UIKit
import Combine



struct SwingAnalysisResultsViewRedesigned: View {
    let video: ProcessingVideo
    @Environment(\.presentationMode) var presentationMode
    
    // Video layout tracking
    @State private var videoRect: CGRect = .zero
    @State private var currentTime: Double = 0
    
    // Overlay toggles
    @State private var showSkeletonOverlay = true // Always show MediaPipe analysis
    @State private var showClubPathOverlay = true
    
    // UI state
    @State private var isFullscreen = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isFullscreen {
                    portraitView(geometry: geometry) // Use same layout for now
                } else {
                    portraitView(geometry: geometry)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Portrait View (Main Layout)
    
    private func portraitView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Full screen video player
            videoPlayerView(height: geometry.size.height)
            
            VStack {
                // Minimal header overlay
                headerView
                    .background(Color.black.opacity(0.7))
                
                Spacer()
                
                // Essential metrics panel overlay at bottom
                metricsPanel
                    .background(Color.black.opacity(0.8))
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("Swing Analysis")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: shareAnalysis) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Video Player (Hero Element)
    
    private func videoPlayerView(height: CGFloat) -> some View {
        ZStack {
            // Unified Video Player with overlay
            UnifiedVideoPlayerComponent(
                url: video.url,
                configuration: .standard,
                onVideoRectChange: { rect in
                    self.videoRect = rect
                },
                onTimeChange: { time in
                    self.currentTime = time
                }
            ) {
                // MediaPipe overlay as part of the unified component
                if let poseData = video.poseData, !poseData.isEmpty {
                    MediaPipeOverlay(
                        poseData: poseData,
                        currentTime: currentTime,
                        viewSize: CGSize(width: UIScreen.main.bounds.width, height: height),
                        videoSize: video.videoSize,
                        isMirrored: false
                    )
                    .opacity(0.8)
                }
            }
            .frame(height: height)
            .clipped()
            
            // Live data display in top right
            VStack {
                HStack {
                    Spacer()
                    // Always show live data panel
                    liveDataPanel
                        .padding(.top, 20)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
            .allowsHitTesting(false)
            .onAppear {
                print("🦴 SKELETON OVERLAY: Overlay appeared")
                print("   - Has pose data: \(video.poseData != nil)")
                print("   - Pose frames count: \(video.poseData?.count ?? 0)")
            }
        }
    }
    

    
    // MARK: - Clean Skeleton Overlay (without text overlays)
    
    @ViewBuilder
    private var cleanSkeletonOverlay: some View {
        GeometryReader { geometry in
            // Placeholder for skeleton overlay - removed TestCoordinateOverlay
            EmptyView()
        }
    }
    
    // MARK: - Live Data Panel
    
    private var liveDataPanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let _ = video.poseData, let currentFrame = getCurrentPoseFrame() {
                // Hip rotation
                LiveDataItem(
                    label: "Hip",
                    value: "\(Int(calculateHipAngle(frame: currentFrame)))°",
                    color: .yellow
                )
                
                // Shoulder rotation
                LiveDataItem(
                    label: "Shoulder", 
                    value: "\(Int(calculateShoulderAngle(frame: currentFrame)))°",
                    color: .cyan
                )
                
                // Spine angle
                LiveDataItem(
                    label: "Spine",
                    value: "\(Int(calculateSpineAngle(frame: currentFrame)))°", 
                    color: .orange
                )
                
                // Enhanced biomechanics - calculate once for performance
                let enhancedMetrics = calculateEnhancedBiomechanics(frame: currentFrame)
                
                LiveDataItem(
                    label: "L Elbow",
                    value: "\(Int(enhancedMetrics.elbowAngles.left))°",
                    color: .green
                )
                
                LiveDataItem(
                    label: "R Elbow", 
                    value: "\(Int(enhancedMetrics.elbowAngles.right))°",
                    color: .green
                )
                
                LiveDataItem(
                    label: "L Knee",
                    value: "\(Int(enhancedMetrics.kneeFlexions.left))°",
                    color: .purple
                )
                
                LiveDataItem(
                    label: "R Knee",
                    value: "\(Int(enhancedMetrics.kneeFlexions.right))°", 
                    color: .purple
                )
                
                LiveDataItem(
                    label: "Stance",
                    value: String(format: "%.2f", enhancedMetrics.stanceMetrics.width),
                    color: .pink
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    

    

    
    // MARK: - Essential Metrics Panel with Live Data
    
    private var metricsPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                // Tempo - Live updating
                LiveSwingAnalysisMetricCard(
                    title: "Tempo",
                    value: String(format: "%.1f:1", getLiveTempo()),
                    unit: "",
                    color: tempoColor(getLiveTempo()),
                    icon: "metronome"
                )
                
                // Swing Path - Live updating
                LiveSwingAnalysisMetricCard(
                    title: "Swing Path",
                    value: getLiveSwingPathDescription(),
                    unit: "",
                    color: swingPathColor(getLiveSwingPathDeviation()),
                    icon: "arrow.triangle.swap"
                )
            }
            .padding(.horizontal, 16)
            
            // Enhanced AI Feedback (if available)
            if let enhancedAnalysis = video.enhancedAnalysis {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        
                        Text("AI Feedback")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Gemini")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if let feedback = enhancedAnalysis.geminiFeedback {
                        Text(feedback)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Quick improvements summary
                    if !enhancedAnalysis.geminiImprovements.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key Focus Areas:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            ForEach(Array(enhancedAnalysis.geminiImprovements.prefix(2).enumerated()), id: \.offset) { index, improvement in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text(improvement)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(2)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.95))
    }
    

    
    // MARK: - Helper Methods
    
    private func shareAnalysis() {
        // TODO: Implement share functionality
    }
    
    // MARK: - Color and Formatting Helpers
    

    
    private func tempoColor(_ tempo: Double) -> Color {
        let ideal = 3.0
        let difference = abs(tempo - ideal)
        switch difference {
        case 0..<0.5: return .green
        case 0.5..<1.0: return .yellow
        default: return .orange
        }
    }
    
    private func swingPathColor(_ deviation: Double) -> Color {
        switch abs(deviation) {
        case 0..<2.0: return .green
        case 2.0..<5.0: return .yellow
        default: return .orange
        }
    }
    
    private func tempoDescription(_ tempo: Double) -> String {
        guard tempo.isFinite else { return "Good tempo" }
        return String(format: "%.1f:1", tempo)
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
              frame.confidence[7] > 0.8, // left hip
              frame.confidence[8] > 0.8  // right hip
        else { return 0.0 }
        
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        return abs(atan2(hipVector.y, hipVector.x) * 180 / .pi)
    }
    
    private func calculateShoulderAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 2,
              frame.confidence[1] > 0.8, // left shoulder
              frame.confidence[2] > 0.8  // right shoulder
        else { return 0.0 }
        
        let leftShoulder = frame.keypoints[1]
        let rightShoulder = frame.keypoints[2]
        let shoulderVector = CGPoint(x: rightShoulder.x - leftShoulder.x, y: rightShoulder.y - leftShoulder.y)
        return abs(atan2(shoulderVector.y, shoulderVector.x) * 180 / .pi)
    }
    
    private func calculateSpineAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 8,
              frame.confidence[0] > 0.8, // nose
              frame.confidence[7] > 0.8, // left hip
              frame.confidence[8] > 0.8  // right hip
        else { return 0.0 }
        
        let nose = frame.keypoints[0]
        let midHip = CGPoint(
            x: (frame.keypoints[7].x + frame.keypoints[8].x) / 2,
            y: (frame.keypoints[7].y + frame.keypoints[8].y) / 2
        )
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        return abs(atan2(spineVector.x, spineVector.y) * 180 / .pi)
    }
    

    
    private func getLiveTempo() -> Double {
        return video.analysisResults?.tempo ?? 3.0
    }
    
    private func getLiveSwingPathDeviation() -> Double {
        return video.analysisResults?.swingPathDeviation ?? 0.0
    }
    
    // MARK: - Enhanced Biomechanics Calculations
    
    private struct EnhancedBiomechanics {
        let elbowAngles: (left: Double, right: Double)
        let kneeFlexions: (left: Double, right: Double)
        let stanceMetrics: (width: Double, balance: Double)
    }
    
    private func calculateEnhancedBiomechanics(frame: PoseFrameData) -> EnhancedBiomechanics {
        return EnhancedBiomechanics(
            elbowAngles: calculateElbowAngles(frame: frame),
            kneeFlexions: calculateKneeFlexion(frame: frame),
            stanceMetrics: calculateStanceMetrics(frame: frame)
        )
    }
    
    private func calculateElbowAngles(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftElbow: Double = 0
        var rightElbow: Double = 0
        
        // Left elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count > 5,
           frame.confidence[1] > 0.8, // left shoulder
           frame.confidence[3] > 0.8, // left elbow  
           frame.confidence[5] > 0.8 { // left wrist
            leftElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[1], // shoulder
                vertex: frame.keypoints[3], // elbow
                p3: frame.keypoints[5] // wrist
            )
        }
        
        // Right elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count > 6,
           frame.confidence[2] > 0.8, // right shoulder
           frame.confidence[4] > 0.8, // right elbow
           frame.confidence[6] > 0.8 { // right wrist
            rightElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[2], // shoulder
                vertex: frame.keypoints[4], // elbow
                p3: frame.keypoints[6] // wrist
            )
        }
        
        return (left: leftElbow, right: rightElbow)
    }
    
    private func calculateKneeFlexion(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftKnee: Double = 0
        var rightKnee: Double = 0
        
        // Left knee flexion (hip-knee-ankle)
        if frame.keypoints.count > 11,
           frame.confidence[7] > 0.8, // left hip
           frame.confidence[9] > 0.8, // left knee
           frame.confidence[11] > 0.8 { // left ankle
            leftKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[7], // hip
                vertex: frame.keypoints[9], // knee
                p3: frame.keypoints[11] // ankle
            )
        }
        
        // Right knee flexion (hip-knee-ankle)
        if frame.keypoints.count > 12,
           frame.confidence[8] > 0.8, // right hip
           frame.confidence[10] > 0.8, // right knee
           frame.confidence[12] > 0.8 { // right ankle
            rightKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[8], // hip
                vertex: frame.keypoints[10], // knee
                p3: frame.keypoints[12] // ankle
            )
        }
        
        return (left: leftKnee, right: rightKnee)
    }
    
    private func calculateStanceMetrics(frame: PoseFrameData) -> (width: Double, balance: Double) {
        guard frame.keypoints.count > 12,
              frame.confidence[11] > 0.8, // left ankle
              frame.confidence[12] > 0.8, // right ankle
              frame.confidence[7] > 0.8, // left hip
              frame.confidence[8] > 0.8 else { // right hip
            return (width: 0, balance: 0)
        }
        
        let leftAnkle = frame.keypoints[11]
        let rightAnkle = frame.keypoints[12]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        // Stance width (distance between ankles)
        let stanceWidth = sqrt(pow(rightAnkle.x - leftAnkle.x, 2) + pow(rightAnkle.y - leftAnkle.y, 2))
        
        // Balance calculation (center of mass relative to feet)
        let hipCenter = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        let footCenter = CGPoint(x: (leftAnkle.x + rightAnkle.x) / 2, y: (leftAnkle.y + rightAnkle.y) / 2)
        let balanceOffset = sqrt(pow(hipCenter.x - footCenter.x, 2) + pow(hipCenter.y - footCenter.y, 2))
        
        return (width: stanceWidth, balance: balanceOffset)
    }
    
    private func calculateAngleBetweenThreePoints(p1: CGPoint, vertex: CGPoint, p3: CGPoint) -> Double {
        let vector1 = CGPoint(x: p1.x - vertex.x, y: p1.y - vertex.y)
        let vector2 = CGPoint(x: p3.x - vertex.x, y: p3.y - vertex.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        return acos(clampedCosAngle) * 180 / .pi
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

// MARK: - Supporting Views - Using shared components from Components folder

// Removed duplicate LiveDataItem and LiveSwingAnalysisMetricCard - using shared components

