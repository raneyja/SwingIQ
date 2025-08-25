//
//  MediaPipeOverlay.swift
//  SwingIQ
//
//  Minimal MediaPipe overlay - start from scratch
//

import SwiftUI

struct MediaPipeOverlay: View {
    let poseData: [PoseFrameData]
    let currentTime: Double
    let viewSize: CGSize
    let videoSize: CGSize?
    
    var body: some View {
        Canvas { context, size in
            guard let frame = getCurrentFrame() else { return }
            
            // TEST: Draw just the nose as a red dot
            if frame.keypoints.count > 0 && frame.confidence.count > 0 && frame.confidence[0] > 0.5 {
                let nose = frame.keypoints[0]
                let point = CGPoint(
                    x: nose.x * size.width,
                    y: (1.0 - nose.y) * size.height  // Flip Y coordinate
                )
                
                let circle = Path(ellipseIn: CGRect(
                    origin: CGPoint(x: point.x - 10, y: point.y - 10),
                    size: CGSize(width: 20, height: 20)
                ))
                
                context.fill(circle, with: .color(.red))
                
                // Debug info
                context.draw(
                    Text("Nose: \(String(format: "%.2f", nose.x)), \(String(format: "%.2f", nose.y))")
                        .font(.system(size: 12))
                        .foregroundColor(.white),
                    at: CGPoint(x: 20, y: 20)
                )
            }
        }
    }
    
    private func getCurrentFrame() -> PoseFrameData? {
        guard !poseData.isEmpty else { return nil }
        
        return poseData.min {
            abs($0.timestamp - currentTime) < abs($1.timestamp - currentTime)
        }
    }
}
