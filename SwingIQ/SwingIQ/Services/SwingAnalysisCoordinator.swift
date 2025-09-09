//
//  SwingAnalysisCoordinator.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation
import CoreGraphics
import UIKit
import AVFoundation

/// Coordinates between MediaPipe detection and golf-specific analysis services
/// Provides a unified interface for swing analysis components
class SwingAnalysisCoordinator: ObservableObject {
    
    // Core services
    private let mediaPipeService: MediaPipeService
    private let swingPhaseService: SwingPhaseService
    private let golfMetricsService: GolfMetricsService
    private let biomechanicsService: BiomechanicsService
    
    // Published properties that combine results from all services
    @Published var currentSwingPhase: SwingPhase = .unknown
    @Published var swingMetrics: SwingMetrics?
    @Published var poseKeypoints: [CGPoint] = []
    @Published var confidenceScores: [Float] = []
    @Published var isProcessing = false
    @Published var lastError: String?
    
    // MARK: - Initialization
    
    init() {
        self.swingPhaseService = SwingPhaseService()
        self.golfMetricsService = GolfMetricsService()
        self.biomechanicsService = BiomechanicsService()
        
        // Initialize stub MediaPipe service (MediaPipe removed)
        self.mediaPipeService = MediaPipeService(
            swingPhaseService: swingPhaseService,
            golfMetricsService: golfMetricsService
        )
        
        setupServiceIntegration()
    }
    
    private func setupServiceIntegration() {
        // Observe MediaPipe service changes
        mediaPipeService.$poseKeypoints
            .assign(to: &$poseKeypoints)
        
        mediaPipeService.$confidenceScores
            .assign(to: &$confidenceScores)
        
        mediaPipeService.$isProcessing
            .assign(to: &$isProcessing)
        
        mediaPipeService.$lastError
            .assign(to: &$lastError)
        
        // Observe swing phase service changes
        swingPhaseService.$currentSwingPhase
            .assign(to: &$currentSwingPhase)
        
        swingPhaseService.$swingMetrics
            .assign(to: &$swingMetrics)
    }
    
    // MARK: - Public Interface
    
    /// Detect pose in UIImage with comprehensive analysis
    func detectPose(in image: UIImage) async throws -> (keypoints: [CGPoint], confidence: [Float]) {
        return try await mediaPipeService.detectPose(in: image)
    }
    
    /// Detect pose in UIImage with callback
    func detectPose(in image: UIImage, completion: @escaping (Bool) -> Void) {
        mediaPipeService.detectPose(in: image, completion: completion)
    }
    
    /// Detect pose in CMSampleBuffer with callback
    func detectPose(in sampleBuffer: CMSampleBuffer, completion: @escaping (Bool) -> Void) {
        mediaPipeService.detectPose(in: sampleBuffer, completion: completion)
    }
    
    /// Get current swing phase
    func getSwingPhase() -> SwingPhase {
        return swingPhaseService.getSwingPhase()
    }
    
    /// Get current swing metrics
    func getSwingMetrics() -> SwingMetrics? {
        return swingPhaseService.getSwingMetrics()
    }
    
    /// Reset swing analysis
    func resetSwingAnalysis() {
        swingPhaseService.resetSwing()
        golfMetricsService.clearHistory()
    }
    
    // MARK: - Advanced Golf Metrics
    
    /// Get advanced biomechanical metrics
    func getAdvancedMetrics() -> [String: Double] {
        return [
            "shoulderTurnAngle": golfMetricsService.calculateShoulderTurnAngle(),
            "hipRotationAngle": golfMetricsService.calculateHipRotationAngle(),
            "spineAngle": golfMetricsService.calculateSpineAngle(),
            "clubheadSpeed": golfMetricsService.calculateClubheadSpeed(),
            "swingPlane": golfMetricsService.calculateSwingPlane()
        ]
    }
    
    /// Get weight distribution
    func getWeightDistribution() -> (frontFoot: Double, backFoot: Double) {
        return golfMetricsService.calculateWeightDistribution()
    }
    
    /// Get swing position classification
    func getSwingPosition() -> String {
        return golfMetricsService.classifySwingPosition()
    }
    
    /// Calculate detailed biomechanics from frame data
    func calculateDetailedBiomechanics(from frames: [PoseFrameData]) -> [String: Any] {
        return biomechanicsService.calculateDetailedBiomechanics(from: frames)
    }
    
    // MARK: - MediaPipe Model Management
    
    /// Reload MediaPipe model
    func reloadMediaPipeModel() {
        mediaPipeService.loadMediaPipeModel()
    }
}

// MARK: - Backward Compatibility

extension SwingAnalysisCoordinator {
    
    /// Provides backward compatibility for existing code that expects MediaPipeService interface
    var mediaPipeServiceCompat: MediaPipeService {
        return mediaPipeService
    }
    
    /// Legacy method signatures for compatibility
    @available(*, deprecated, message: "Use SwingAnalysisCoordinator methods directly")
    func loadMediaPipeModel() {
        mediaPipeService.loadMediaPipeModel()
    }
}
