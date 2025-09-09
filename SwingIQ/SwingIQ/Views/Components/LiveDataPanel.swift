//
//  LiveDataPanel.swift
//  SwingIQ
//
//  Live data display panel for pose analysis
//

import SwiftUI

struct LiveDataPanel: View {
    let poseData: [PoseFrameData]?
    let currentTime: Double
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let _ = poseData, let currentFrame = getCurrentPoseFrame() {
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
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentPoseFrame() -> PoseFrameData? {
        guard let poseData = poseData, !poseData.isEmpty else { return nil }
        
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
}

struct LiveDataItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }
}
