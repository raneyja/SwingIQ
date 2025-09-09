//
//  AVAsset+Extensions.swift
//  SwingIQ
//
//  Extension to detect video transforms
//

import AVFoundation

extension AVAsset {
    var isHorizontallyFlipped: Bool {
        guard let track = tracks(withMediaType: .video).first else { 
            return false 
        }
        
        let transform = track.preferredTransform
        // Check if transform includes horizontal flip (scaleX = -1, scaleY = 1)
        return transform.a == -1 && transform.d == 1
    }
    
    var videoRotationAngle: Double {
        guard let track = tracks(withMediaType: .video).first else { return 0 }
        let transform = track.preferredTransform
        
        // Calculate rotation angle from transform matrix
        let radians = atan2(transform.b, transform.a)
        return radians * 180 / .pi
    }
    
    var videoTransformInfo: String {
        guard let track = tracks(withMediaType: .video).first else {
            return "No video track"
        }
        
        let transform = track.preferredTransform
        return "Transform matrix: [a=\(transform.a), b=\(transform.b), c=\(transform.c), d=\(transform.d)], rotation=\(videoRotationAngle)°, flipped=\(isHorizontallyFlipped)"
    }
}
