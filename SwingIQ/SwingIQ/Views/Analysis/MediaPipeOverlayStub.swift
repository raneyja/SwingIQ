//
//  MediaPipeOverlayStub.swift
//  SwingIQ
//
//  Stub implementation for MediaPipe overlay when MediaPipe is disabled
//

import SwiftUI

struct MediaPipeOverlay: View {
    let poseData: [PoseFrameData]
    let currentTime: Double
    let viewSize: CGSize
    let videoSize: CGSize?
    let isMirrored: Bool
    
    var body: some View {
        // Stub implementation - shows placeholder when MediaPipe is disabled
        Rectangle()
            .fill(.clear)
            .overlay(
                Text("Pose Analysis Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .opacity(0.7),
                alignment: .topTrailing
            )
    }
}

#Preview {
    MediaPipeOverlay(
        poseData: [],
        currentTime: 0.0,
        viewSize: CGSize(width: 300, height: 200),
        videoSize: CGSize(width: 1920, height: 1080),
        isMirrored: false
    )
}
