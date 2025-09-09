//
//  MediaPipeOverlayStub.swift
//  SwingIQ
//
//  Stub replacement for MediaPipeOverlay after MediaPipe removal
//

import SwiftUI

/// Stub replacement for MediaPipeOverlay that shows disabled message
struct MediaPipeOverlay: View {
    let poseData: [PoseFrameData]
    let currentTime: Double
    let viewSize: CGSize
    let videoSize: CGSize?
    let isMirrored: Bool
    
    var body: some View {
        // Empty overlay - no pose detection message displayed
        Color.clear
    }
}
