//
//  SwingModels.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import CoreGraphics
import SwiftData

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
    let swingSpeed: Double // mph
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

// MARK: - Export Extensions

extension SwingMetrics {
    private enum CodingKeys: String, CodingKey {
        case tempo, balance, swingPathDeviation, unit
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tempo = try container.decode(Double.self, forKey: .tempo)
        balance = try container.decode(Double.self, forKey: .balance)
        swingPathDeviation = try container.decode(Double.self, forKey: .swingPathDeviation)
        // unit is ignored for decoding as it's not stored in core model
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tempo, forKey: .tempo)
        try container.encode(balance, forKey: .balance)
        try container.encode(swingPathDeviation, forKey: .swingPathDeviation)
        try container.encode("metric", forKey: .unit)
    }
}

extension SwingScores {
    private enum CodingKeys: String, CodingKey {
        case overall, tempo, balance, grade
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overall = try container.decode(Double.self, forKey: .overall)
        tempo = try container.decode(Double.self, forKey: .tempo)
        balance = try container.decode(Double.self, forKey: .balance)
        // grade is computed, not stored
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(overall, forKey: .overall)
        try container.encode(tempo, forKey: .tempo)
        try container.encode(balance, forKey: .balance)
        try container.encode(grade, forKey: .grade)
    }
    
    var grade: String {
        switch overall {
        case 0.9...: return "A+"
        case 0.85..<0.9: return "A"
        case 0.8..<0.85: return "A-"
        case 0.75..<0.8: return "B+"
        case 0.7..<0.75: return "B"
        case 0.65..<0.7: return "B-"
        case 0.6..<0.65: return "C+"
        case 0.55..<0.6: return "C"
        case 0.5..<0.55: return "C-"
        default: return "D"
        }
    }
}

extension SwingFault {
    private enum CodingKeys: String, CodingKey {
        case id, type, severity, description, recommendation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID(uuidString: try container.decode(String.self, forKey: .id)) ?? UUID()
        type = FaultType(rawValue: try container.decode(String.self, forKey: .type)) ?? .posture
        severity = FaultSeverity(rawValue: try container.decode(String.self, forKey: .severity)) ?? .low
        description = try container.decode(String.self, forKey: .description)
        recommendation = try container.decode(String.self, forKey: .recommendation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(severity.rawValue, forKey: .severity)
        try container.encode(description, forKey: .description)
        try container.encode(recommendation, forKey: .recommendation)
    }
}

extension SwingRecommendation {
    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id is let with default UUID(), so we ignore the decoded value
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        priority = RecommendationPriority(rawValue: try container.decode(String.self, forKey: .priority)) ?? .low
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(priority.rawValue, forKey: .priority)
    }
}

extension SwingPhaseData {
    private enum CodingKeys: String, CodingKey {
        case phase, startFrame, endFrame, duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = SwingPhase(rawValue: try container.decode(String.self, forKey: .phase)) ?? .unknown
        startFrame = try container.decode(Int.self, forKey: .startFrame)
        endFrame = try container.decode(Int.self, forKey: .endFrame)
        duration = try container.decode(Double.self, forKey: .duration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phase.rawValue, forKey: .phase)
        try container.encode(startFrame, forKey: .startFrame)
        try container.encode(endFrame, forKey: .endFrame)
        try container.encode(duration, forKey: .duration)
    }
}

extension SwingAnalysis {
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, currentPhase, metrics, scores, faults, phases, recommendations, keypointsCount, averageConfidence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID(uuidString: try container.decode(String.self, forKey: .id)) ?? UUID()
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        phase = SwingPhase(rawValue: try container.decode(String.self, forKey: .currentPhase)) ?? .unknown
        metrics = try container.decode(SwingMetrics.self, forKey: .metrics)
        scores = try container.decode(SwingScores.self, forKey: .scores)
        faults = try container.decode([SwingFault].self, forKey: .faults)
        recommendations = try container.decode([SwingRecommendation].self, forKey: .recommendations)
        
        // Convert phases array back to dictionary
        let phasesArray = try container.decode([SwingPhaseData].self, forKey: .phases)
        swingPhases = Dictionary(uniqueKeysWithValues: phasesArray.map { ($0.phase, $0) })
        
        let keypointsCount = try container.decode(Int.self, forKey: .keypointsCount)
        keypoints = Array(repeating: CGPoint.zero, count: keypointsCount)
        
        let avgConfidence = try container.decode(Double.self, forKey: .averageConfidence)
        confidenceScores = Array(repeating: Float(avgConfidence), count: keypointsCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(phase.rawValue, forKey: .currentPhase)
        try container.encode(metrics, forKey: .metrics)
        try container.encode(scores, forKey: .scores)
        try container.encode(faults, forKey: .faults)
        try container.encode(Array(swingPhases.values), forKey: .phases)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(keypoints.count, forKey: .keypointsCount)
        
        let avgConfidence = confidenceScores.isEmpty ? 0.0 : 
            Double(confidenceScores.reduce(0, +)) / Double(confidenceScores.count)
        try container.encode(avgConfidence, forKey: .averageConfidence)
    }
}

// MARK: - Video Analysis Models

struct PoseFrameData: Codable {
    let frameNumber: Int
    let timestamp: TimeInterval
    let keypoints: [CGPoint]
    let confidence: [Float]
}

struct VideoAnalysisResult: Codable {
    let videoURL: URL?
    let totalFrames: Int
    let analyzedFrames: Int
    let duration: Double
    let swingAnalysis: SwingAnalysisData
    let frameAnalytics: FrameAnalytics
    let recommendations: [VideoRecommendation]
    let processedAt: Date
}

struct SwingAnalysisData: Codable {
    let phases: [SwingPhaseInfo]
    let averageMetrics: SwingMetrics
    let peakMetrics: SwingMetrics
    let tempo: Double
}

struct SwingPhaseInfo: Codable {
    let phase: SwingPhase
    let startFrame: Int
    let endFrame: Int
    let duration: Double
}

struct FrameAnalytics: Codable {
    let totalFrames: Int
    let highConfidenceFrames: Int
    let mediumConfidenceFrames: Int
    let lowConfidenceFrames: Int
    let averageConfidence: Double
    let confidenceRange: ConfidenceRange
    
    struct ConfidenceRange: Codable {
        let min: Double
        let max: Double
    }
}

struct VideoRecommendation: Codable {
    let type: RecommendationType
    let priority: Priority
    let title: String
    let description: String
    let frameReferences: [Int]
    
    enum RecommendationType: String, Codable, CaseIterable {
        case technique
        case tempo
        case power
        case balance
        case consistency
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }
}


