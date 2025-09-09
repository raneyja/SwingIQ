//
//  BiomechanicsService.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation
import CoreGraphics

class BiomechanicsService: ObservableObject {
    
    // Integration with new golf metrics service
    private let golfMetricsService = GolfMetricsService()
    
    // MARK: - Public Methods
    
    func calculateDetailedBiomechanics(from frames: [PoseFrameData]) -> [String: Any] {
        guard !frames.isEmpty else { return [:] }
        
        var hipAngles: [Double] = []
        var shoulderAngles: [Double] = []
        var spineAngles: [Double] = []
        var weightDistributions: [(front: Double, back: Double)] = []
        var wristVelocities: [Double] = []
        var elbowAngles: [(left: Double, right: Double)] = []
        var headPositions: [CGPoint] = []
        var kneeFlexions: [(left: Double, right: Double)] = []
        var stanceMetrics: [(width: Double, balance: Double)] = []
        
        for frame in frames {
            if let hipAngle = calculateHipAngle(frame: frame) {
                hipAngles.append(hipAngle)
            }
            
            if let shoulderAngle = calculateShoulderAngle(frame: frame) {
                shoulderAngles.append(shoulderAngle)
            }
            
            if let spineAngle = calculateSpineAngle(frame: frame) {
                spineAngles.append(spineAngle)
            }
            
            let weightDist = calculateWeightDistribution(frame: frame)
            weightDistributions.append(weightDist)
            
            if let velocity = calculateWristVelocity(frame: frame, in: frames) {
                wristVelocities.append(velocity)
            }
            
            let elbowAngle = calculateElbowAngles(frame: frame)
            elbowAngles.append(elbowAngle)
            
            let headPos = calculateHeadPosition(frame: frame)
            headPositions.append(headPos)
            
            let kneeFlexion = calculateKneeFlexion(frame: frame)
            kneeFlexions.append(kneeFlexion)
            
            let stance = calculateStanceMetrics(frame: frame)
            stanceMetrics.append(stance)
        }
        
        // Calculate aggregate metrics - broken into parts for compiler
        let hipAverage = hipAngles.isEmpty ? 0 : hipAngles.reduce(0, +) / Double(hipAngles.count)
        let hipPeak = hipAngles.max() ?? 0
        let hipConsistency = calculateBiomechanicalConsistency(hipAngles)
        let hipMetrics: [String: Any] = [
            "average": hipAverage,
            "peak": hipPeak,
            "consistency": hipConsistency
        ]
        
        let shoulderMetrics: [String: Any] = [
            "average": shoulderAngles.isEmpty ? 0 : shoulderAngles.reduce(0, +) / Double(shoulderAngles.count),
            "peak": shoulderAngles.max() ?? 0,
            "consistency": calculateBiomechanicalConsistency(shoulderAngles)
        ]
        
        let spineMetrics: [String: Any] = [
            "average": spineAngles.isEmpty ? 0 : spineAngles.reduce(0, +) / Double(spineAngles.count),
            "consistency": calculateBiomechanicalConsistency(spineAngles)
        ]
        
        let weightMetrics: [String: Any] = [
            "averageFrontFoot": weightDistributions.isEmpty ? 50 : weightDistributions.map { $0.front }.reduce(0, +) / Double(weightDistributions.count)
        ]
        
        let wristMetrics: [String: Any] = [
            "peak": wristVelocities.max() ?? 0,
            "average": wristVelocities.isEmpty ? 0 : wristVelocities.reduce(0, +) / Double(wristVelocities.count)
        ]
        
        let elbowMetrics: [String: Any] = [
            "averageLeftElbow": elbowAngles.isEmpty ? 0 : elbowAngles.map { $0.left }.reduce(0, +) / Double(elbowAngles.count),
            "averageRightElbow": elbowAngles.isEmpty ? 0 : elbowAngles.map { $0.right }.reduce(0, +) / Double(elbowAngles.count),
            "maxLeftFlexion": elbowAngles.map { $0.left }.max() ?? 0,
            "maxRightFlexion": elbowAngles.map { $0.right }.max() ?? 0
        ]
        
        let headMetrics: [String: Any] = [
            "stability": calculateHeadStability(headPositions),
            "averagePosition": calculateAveragePosition(headPositions)
        ]
        
        let kneeMetrics: [String: Any] = [
            "averageLeftFlexion": kneeFlexions.isEmpty ? 0 : kneeFlexions.map { $0.left }.reduce(0, +) / Double(kneeFlexions.count),
            "averageRightFlexion": kneeFlexions.isEmpty ? 0 : kneeFlexions.map { $0.right }.reduce(0, +) / Double(kneeFlexions.count),
            "flexionConsistency": calculateBiomechanicalConsistency(kneeFlexions.map { ($0.left + $0.right) / 2 })
        ]
        
        let balanceRange: [String: Any] = [
            "average": stanceMetrics.isEmpty ? 0 : stanceMetrics.map { $0.balance }.reduce(0, +) / Double(stanceMetrics.count),
            "min": stanceMetrics.map { $0.balance }.min() ?? 0,
            "max": stanceMetrics.map { $0.balance }.max() ?? 0
        ]
        
        let stanceMetrics_dict: [String: Any] = [
            "averageStanceWidth": stanceMetrics.isEmpty ? 0 : stanceMetrics.map { $0.width }.reduce(0, +) / Double(stanceMetrics.count),
            "stanceConsistency": calculateBiomechanicalConsistency(stanceMetrics.map { $0.width }),
            "balanceRange": balanceRange
        ]
        
        return [
            "hipRotation": hipMetrics,
            "shoulderRotation": shoulderMetrics,
            "spineAngle": spineMetrics,
            "weightDistribution": weightMetrics,
            "wristVelocity": wristMetrics,
            "elbowAnalysis": elbowMetrics,
            "headMovement": headMetrics,
            "kneeAction": kneeMetrics,
            "stanceAnalysis": stanceMetrics_dict
        ]
    }
    
    // MARK: - Individual Frame Analysis Methods
    
    private func calculateHipAngle(frame: PoseFrameData) -> Double? {
        guard frame.keypoints.count >= 13,
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { return nil } // right hip
        
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        let angle = atan2(hipVector.y, hipVector.x) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateShoulderAngle(frame: PoseFrameData) -> Double? {
        guard frame.keypoints.count >= 13,
              frame.keypoints[1] != .zero, // left shoulder
              frame.keypoints[2] != .zero else { return nil } // right shoulder
        
        let leftShoulder = frame.keypoints[1]
        let rightShoulder = frame.keypoints[2]
        
        let shoulderVector = CGPoint(x: rightShoulder.x - leftShoulder.x, y: rightShoulder.y - leftShoulder.y)
        let angle = atan2(shoulderVector.y, shoulderVector.x) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateSpineAngle(frame: PoseFrameData) -> Double? {
        guard frame.keypoints.count >= 13,
              frame.keypoints[0] != .zero, // nose
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { return nil } // right hip
        
        let nose = frame.keypoints[0]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        let midHip = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        let angle = atan2(spineVector.x, spineVector.y) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateWeightDistribution(frame: PoseFrameData) -> (front: Double, back: Double) {
        guard frame.keypoints.count >= 13,
              frame.keypoints[9] != .zero, // left ankle
              frame.keypoints[10] != .zero, // right ankle
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { return (50, 50) } // right hip
        
        let leftAnkle = frame.keypoints[9]
        let rightAnkle = frame.keypoints[10]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        let hipCenter = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        
        let totalWidth = abs(rightAnkle.x - leftAnkle.x)
        let frontWeight = totalWidth > 0 ? abs(hipCenter.x - leftAnkle.x) / totalWidth * 100 : 50
        return (front: frontWeight, back: 100 - frontWeight)
    }
    
    private func calculateWristVelocity(frame: PoseFrameData, in allFrames: [PoseFrameData]) -> Double? {
        guard let currentIndex = allFrames.firstIndex(where: { $0.frameNumber == frame.frameNumber }),
              currentIndex > 0,
              frame.keypoints.count >= 13,
              frame.keypoints[5] != .zero else { return nil } // left wrist
        
        let previousFrame = allFrames[currentIndex - 1]
        guard previousFrame.keypoints.count >= 13,
              previousFrame.keypoints[5] != .zero else { return nil }
        
        let currentWrist = frame.keypoints[5]
        let previousWrist = previousFrame.keypoints[5]
        let timeInterval = frame.timestamp - previousFrame.timestamp
        
        guard timeInterval > 0 else { return nil }
        
        let dx = currentWrist.x - previousWrist.x
        let dy = currentWrist.y - previousWrist.y
        let velocity = sqrt(dx * dx + dy * dy) / timeInterval
        
        return velocity
    }
    
    private func calculateElbowAngles(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftElbow: Double = 0
        var rightElbow: Double = 0
        
        // Left elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count >= 17,
           frame.keypoints[1] != .zero, // left shoulder
           frame.keypoints[3] != .zero, // left elbow  
           frame.keypoints[5] != .zero { // left wrist
            leftElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[1], // shoulder
                vertex: frame.keypoints[3], // elbow
                p3: frame.keypoints[5] // wrist
            )
        }
        
        // Right elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count >= 17,
           frame.keypoints[2] != .zero, // right shoulder
           frame.keypoints[4] != .zero, // right elbow
           frame.keypoints[6] != .zero { // right wrist
            rightElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[2], // shoulder
                vertex: frame.keypoints[4], // elbow
                p3: frame.keypoints[6] // wrist
            )
        }
        
        return (left: leftElbow, right: rightElbow)
    }
    
    private func calculateHeadPosition(frame: PoseFrameData) -> CGPoint {
        guard frame.keypoints.count >= 13,
              frame.keypoints[0] != .zero else { 
            return CGPoint.zero 
        }
        
        return frame.keypoints[0] // nose position as head reference
    }
    
    private func calculateKneeFlexion(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftKnee: Double = 0
        var rightKnee: Double = 0
        
        // Left knee flexion (hip-knee-ankle)
        if frame.keypoints.count >= 13,
           frame.keypoints[7] != .zero, // left hip
           frame.keypoints[9] != .zero, // left knee
           frame.keypoints[11] != .zero { // left ankle
            leftKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[7], // hip
                vertex: frame.keypoints[9], // knee
                p3: frame.keypoints[11] // ankle
            )
        }
        
        // Right knee flexion (hip-knee-ankle)
        if frame.keypoints.count >= 13,
           frame.keypoints[8] != .zero, // right hip
           frame.keypoints[10] != .zero, // right knee
           frame.keypoints[12] != .zero { // right ankle
            rightKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[8], // hip
                vertex: frame.keypoints[10], // knee
                p3: frame.keypoints[12] // ankle
            )
        }
        
        return (left: leftKnee, right: rightKnee)
    }
    
    private func calculateStanceMetrics(frame: PoseFrameData) -> (width: Double, balance: Double) {
        guard frame.keypoints.count >= 13,
              frame.keypoints[11] != .zero, // left ankle
              frame.keypoints[12] != .zero, // right ankle
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { // right hip
            return (width: 0, balance: 0)
        }
        
        let leftAnkle = frame.keypoints[11]
        let rightAnkle = frame.keypoints[12]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        // Stance width (distance between ankles)
        let stanceWidth = sqrt(pow(rightAnkle.x - leftAnkle.x, 2) + pow(rightAnkle.y - leftAnkle.y, 2))
        
        // Balance calculation (center of mass relative to feet)
        let hipCenter = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        let footCenter = CGPoint(x: (leftAnkle.x + rightAnkle.x) / 2, y: (leftAnkle.y + rightAnkle.y) / 2)
        let balanceOffset = sqrt(pow(hipCenter.x - footCenter.x, 2) + pow(hipCenter.y - footCenter.y, 2))
        
        return (width: stanceWidth, balance: balanceOffset)
    }
    
    // MARK: - Utility Methods
    
    private func calculateAngleBetweenThreePoints(p1: CGPoint, vertex: CGPoint, p3: CGPoint) -> Double {
        let vector1 = CGPoint(x: p1.x - vertex.x, y: p1.y - vertex.y)
        let vector2 = CGPoint(x: p3.x - vertex.x, y: p3.y - vertex.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        return acos(clampedCosAngle) * 180 / .pi
    }
    
    private func calculateBiomechanicalConsistency(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 1.0 }
        
        let average = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - average, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        return max(0, 1.0 - (standardDeviation / average))
    }
    
    private func calculateHeadStability(_ positions: [CGPoint]) -> Double {
        guard positions.count > 1 else { return 1.0 }
        
        let distances: [Double] = positions.enumerated().compactMap { index, position in
            guard index > 0 else { return nil }
            let prev = positions[index - 1]
            return sqrt(pow(position.x - prev.x, 2) + pow(position.y - prev.y, 2))
        }
        
        let averageMovement = distances.isEmpty ? 0 : distances.reduce(0, +) / Double(distances.count)
        return max(0, 1.0 - (averageMovement * 10)) // Scale for 0-1 range
    }
    
    private func calculateAveragePosition(_ positions: [CGPoint]) -> [String: Double] {
        guard !positions.isEmpty else { return ["x": 0, "y": 0] }
        
        let avgX = positions.map { $0.x }.reduce(0, +) / Double(positions.count)
        let avgY = positions.map { $0.y }.reduce(0, +) / Double(positions.count)
        
        return ["x": avgX, "y": avgY]
    }
}
