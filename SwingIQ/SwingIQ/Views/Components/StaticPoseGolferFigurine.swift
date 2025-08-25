//
//  StaticPoseGolferFigurine.swift
//  SwingIQ
//
//  3D Golfer figurine using existing pose system
//

import SwiftUI
import SceneKit

struct StaticPoseGolferFigurine: View {
    @State private var currentTime: Double = 0.0
    
    var body: some View {
        ZStack {
            // Use your existing 3D pose rendering with a static "perfect swing" pose
            SwingPose3DView(
                poseData: [createPerfectSwingPoseData()],
                currentTime: $currentTime,
                duration: 1.0
            )
            .frame(width: 200, height: 280)
        }
    }
    
    // Create a static pose representing perfect follow-through
    private func createPerfectSwingPoseData() -> PoseFrameData {
        // Create 33 keypoints (MediaPipe pose model has 33 landmarks)
        var keypoints = Array(repeating: CGPoint.zero, count: 33)
        var confidences = Array(repeating: Float(0.9), count: 33)
        
        // Set key golf pose landmarks for follow-through
        keypoints[0] = CGPoint(x: 0.52, y: 0.25)  // nose
        keypoints[11] = CGPoint(x: 0.45, y: 0.35) // left_shoulder
        keypoints[12] = CGPoint(x: 0.58, y: 0.37) // right_shoulder
        keypoints[13] = CGPoint(x: 0.35, y: 0.45) // left_elbow
        keypoints[14] = CGPoint(x: 0.75, y: 0.28) // right_elbow
        keypoints[15] = CGPoint(x: 0.42, y: 0.55) // left_wrist
        keypoints[16] = CGPoint(x: 0.82, y: 0.25) // right_wrist
        keypoints[23] = CGPoint(x: 0.47, y: 0.58) // left_hip
        keypoints[24] = CGPoint(x: 0.53, y: 0.58) // right_hip
        keypoints[25] = CGPoint(x: 0.45, y: 0.75) // left_knee
        keypoints[26] = CGPoint(x: 0.52, y: 0.73) // right_knee
        keypoints[27] = CGPoint(x: 0.44, y: 0.92) // left_ankle
        keypoints[28] = CGPoint(x: 0.51, y: 0.90) // right_ankle
        
        return PoseFrameData(
            frameNumber: 0,
            timestamp: 0.0,
            keypoints: keypoints,
            confidence: confidences
        )
    }
}

#Preview {
    StaticPoseGolferFigurine()
        .background(Color.white)
}
