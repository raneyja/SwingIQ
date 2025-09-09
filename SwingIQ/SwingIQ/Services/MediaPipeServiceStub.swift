//
//  MediaPipeServiceStub.swift
//  SwingIQ
//
//  Stub replacement for MediaPipeService after MediaPipe removal
//

import Foundation
import AVFoundation
import UIKit

/// Stub replacement for MediaPipeService that provides empty pose detection
class MediaPipeService: ObservableObject {
    @Published var isProcessing = false
    @Published var poseKeypoints: [CGPoint] = []
    @Published var confidenceScores: [Float] = []
    @Published var lastError: String? = "Pose detection disabled - MediaPipe removed"
    
    var poseLandmarker: Bool? { return nil }
    
    init(swingPhaseService: SwingPhaseService? = nil, golfMetricsService: GolfMetricsService? = nil) {
        // Stub initialization - no MediaPipe dependencies
    }
    
    func updateVideoOrientation(from transform: CGAffineTransform) {
        // No-op stub
    }
    
    func detectPose(in image: UIImage) async throws -> (keypoints: [CGPoint], confidence: [Float]) {
        throw NSError(domain: "PoseDetectionDisabled", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Pose detection is disabled - MediaPipe has been removed"
        ])
    }
    
    func detectPose(in image: UIImage, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    func detectPose(in sampleBuffer: CMSampleBuffer, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    func loadMediaPipeModel() {
        lastError = "MediaPipe model loading disabled"
    }
    
    func setSwingPhaseService(_ service: SwingPhaseService) {
        // No-op stub
    }
    
    func setGolfMetricsService(_ service: GolfMetricsService) {
        // No-op stub
    }
}

// MARK: - VideoOrientation Enum (preserved for compatibility)
enum VideoOrientation {
    case portraitUp, portraitUpsideDown, landscapeLeft, landscapeRight
}
