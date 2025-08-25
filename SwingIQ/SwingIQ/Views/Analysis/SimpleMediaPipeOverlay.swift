//
//  SimpleMediaPipeOverlay.swift
//  SwingIQ
//
//  Simple MediaPipe overlay - kept for backward compatibility
//

import SwiftUI

struct SimpleMediaPipeOverlay: View {
    let poseData: [PoseFrameData]
    let currentTime: Double
    let viewSize: CGSize
    
    var body: some View {
        MediaPipeOverlay(
            poseData: poseData,
            currentTime: currentTime,
            viewSize: viewSize,
            videoSize: nil
        )
    }
}
