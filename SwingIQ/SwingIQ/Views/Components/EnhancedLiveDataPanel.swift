//
//  EnhancedLiveDataPanel.swift
//  SwingIQ
//
//  Enhanced live data panel with biomechanics calculations
//

import SwiftUI

struct EnhancedLiveDataPanel: View {
    let poseData: [PoseFrameData]?
    let currentTime: Double
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let _ = poseData, let currentFrame = getCurrentPoseFrame() {
                basicMetricsGroup(currentFrame)
                enhancedBiometricsGroup(currentFrame)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    // MARK: - Basic Metrics Group
    
    private func basicMetricsGroup(_ frame: PoseFrameData) -> some View {
        Group {
            LiveDataItem(
                label: "Hip",
                value: "\(Int(BiomechanicsCalculator.calculateHipAngle(frame: frame)))°",
                color: .yellow
            )
            
            LiveDataItem(
                label: "Shoulder",
                value: "\(Int(BiomechanicsCalculator.calculateShoulderAngle(frame: frame)))°",
                color: .cyan
            )
            
            LiveDataItem(
                label: "Spine",
                value: "\(Int(BiomechanicsCalculator.calculateSpineAngle(frame: frame)))°",
                color: .orange
            )
        }
    }
    
    // MARK: - Enhanced Biomechanics Group
    
    private func enhancedBiometricsGroup(_ frame: PoseFrameData) -> some View {
        let enhancedMetrics = BiomechanicsCalculator.calculateEnhancedBiomechanics(frame: frame)
        
        return Group {
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
    
    // MARK: - Helper Methods
    
    private func getCurrentPoseFrame() -> PoseFrameData? {
        guard let poseData = poseData, !poseData.isEmpty else { return nil }
        
        let frameIndex = poseData.enumerated().min {
            abs($0.element.timestamp - currentTime) < abs($1.element.timestamp - currentTime)
        }?.offset ?? 0
        
        return poseData[max(0, min(frameIndex, poseData.count - 1))]
    }
}
