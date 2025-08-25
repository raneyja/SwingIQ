//
//  SwingModels.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import CoreGraphics

// MARK: - Core Swing Data Models

/// Represents a single frame of pose data during a golf swing
struct PoseFrame: Codable {
    let keypoints: [CGPoint]
    let confidences: [Float]
    let timestamp: Date
    
    // Golf-specific landmark indices (matching MediaPipe pose model)
    enum LandmarkIndex: Int {
        case nose = 0
        case leftShoulder = 11, rightShoulder = 12
        case leftElbow = 13, rightElbow = 14
        case leftWrist = 15, rightWrist = 16
        case leftHip = 23, rightHip = 24
        case leftKnee = 25, rightKnee = 26
        case leftAnkle = 27, rightAnkle = 28
    }
    
    func landmark(_ index: LandmarkIndex) -> CGPoint? {
        let adjustedIndex = getAdjustedIndex(for: index)
        guard adjustedIndex < keypoints.count else { return nil }
        return keypoints[adjustedIndex]
    }
    
    private func getAdjustedIndex(for landmark: LandmarkIndex) -> Int {
        // Map MediaPipe indices to our extracted keypoints array
        let relevantIndices = [0, 11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28]
        guard let position = relevantIndices.firstIndex(of: landmark.rawValue) else { return -1 }
        return position
    }
}

/// Different phases of a golf swing
enum SwingPhase: String, Codable, CaseIterable, Hashable {
    case address
    case takeaway
    case backswing
    case transition
    case downswing
    case impact
    case followThrough
    case finish
    case unknown
    
    var description: String {
        switch self {
        case .address: return "Address"
        case .takeaway: return "Takeaway"
        case .backswing: return "Backswing"
        case .transition: return "Transition"
        case .downswing: return "Downswing"
        case .impact: return "Impact"
        case .followThrough: return "Follow Through"
        case .finish: return "Finish"
        case .unknown: return "Unknown"
        }
    }
}

/// Core swing metrics (pose-based measurements only)
struct SwingMetrics: Codable, Hashable {
    let tempo: Double // ratio
    let balance: Double // score 0-1
    let swingPathDeviation: Double // degrees (negative = inside, positive = outside)
    
    var tempoFormatted: String {
        return String(format: "%.1f:1", tempo)
    }
    
    var balanceFormatted: String {
        return String(format: "%.0f%%", balance * 100)
    }
    
    var swingPathDeviationFormatted: String {
        let absValue = abs(swingPathDeviation)
        let direction = swingPathDeviation < 0 ? "inside" : "outside"
        return String(format: "%.1f° %@", absValue, direction)
    }
    
    var swingPathDescription: String {
        if abs(swingPathDeviation) < 2.0 {
            return "On plane"
        } else if swingPathDeviation < 0 {
            return "Inside-out"
        } else {
            return "Outside-in"
        }
    }
}

/// Overall swing performance scores  
struct SwingScores: Codable, Hashable {
    let overall: Double
    let tempo: Double
    let balance: Double
}

/// AI-generated swing recommendations
struct SwingRecommendation: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let priority: RecommendationPriority
    
    enum RecommendationPriority: String, Codable, CaseIterable, Hashable {
        case high, medium, low
    }
}

/// Detected swing faults with improvement suggestions
struct SwingFault: Identifiable, Codable, Hashable {
    let id: UUID
    let type: FaultType
    let severity: FaultSeverity
    let description: String
    let recommendation: String
    
    enum FaultType: String, Codable, CaseIterable, Hashable {
        case posture
        case swingPlane
        case tempo
        case balance
    }
    
    enum FaultSeverity: String, Codable, CaseIterable, Hashable {
        case low
        case medium
        case high
    }
}

/// Information about a specific swing phase
struct SwingPhaseData: Codable, Hashable {
    let phase: SwingPhase
    let startFrame: Int
    let endFrame: Int
    let duration: Double
}

/// Complete swing analysis result
struct SwingAnalysis: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let phase: SwingPhase
    let metrics: SwingMetrics
    let keypoints: [CGPoint]
    let confidenceScores: [Float]
    let swingPhases: [SwingPhase: SwingPhaseData]
    let faults: [SwingFault]
    let scores: SwingScores
    let recommendations: [SwingRecommendation]
    
    init(id: UUID = UUID(), timestamp: Date, phase: SwingPhase, metrics: SwingMetrics, keypoints: [CGPoint], confidenceScores: [Float], swingPhases: [SwingPhase: SwingPhaseData] = [:], faults: [SwingFault] = [], scores: SwingScores, recommendations: [SwingRecommendation] = []) {
        self.id = id
        self.timestamp = timestamp
        self.phase = phase
        self.metrics = metrics
        self.keypoints = keypoints
        self.confidenceScores = confidenceScores
        self.swingPhases = swingPhases
        self.faults = faults
        self.scores = scores
        self.recommendations = recommendations
    }
    
    // Custom Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SwingAnalysis, rhs: SwingAnalysis) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Video Analysis Models

struct VideoAnalysisResult {
    let videoURL: URL?
    let totalFrames: Int
    let analyzedFrames: Int
    let duration: Double
    let swingAnalysis: SwingAnalysisData
    let frameAnalytics: FrameAnalytics
    let recommendations: [VideoRecommendation]
    let processedAt: Date
}

struct SwingAnalysisData {
    let phases: [SwingPhaseInfo]
    let averageMetrics: SwingMetrics
    let peakMetrics: SwingMetrics
    let tempo: Double
}

struct SwingPhaseInfo {
    let phase: SwingPhase
    let startFrame: Int
    let endFrame: Int
    let duration: Double
}

struct FrameAnalytics {
    let totalFrames: Int
    let highConfidenceFrames: Int
    let mediumConfidenceFrames: Int
    let lowConfidenceFrames: Int
    let averageConfidence: Double
    let confidenceRange: (min: Double, max: Double)
}

struct VideoRecommendation {
    let type: RecommendationType
    let priority: Priority
    let title: String
    let description: String
    let frameReferences: [Int]
    
    enum RecommendationType {
        case technique
        case tempo
        case power
        case balance
        case consistency
    }
    
    enum Priority {
        case low
        case medium
        case high
    }
}


