//
//  GolfMetricsService.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation
import CoreGraphics

/// Service responsible for calculating advanced golf-specific biomechanical metrics
class GolfMetricsService: ObservableObject {
    
    // Pose history for complex calculations
    private var poseHistory: [PoseFrame] = []
    private let maxHistoryFrames = 30
    
    // MARK: - Public Interface
    
    func addPoseFrame(_ frame: PoseFrame) {
        poseHistory.append(frame)
        
        // Maintain history limit
        if poseHistory.count > maxHistoryFrames {
            poseHistory.removeFirst()
        }
    }
    
    func clearHistory() {
        poseHistory.removeAll()
    }
    
    // MARK: - Advanced Golf Metrics
    
    func calculateShoulderTurnAngle() -> Double {
        guard let currentFrame = poseHistory.last,
              let leftShoulder = currentFrame.landmark(.leftShoulder),
              let rightShoulder = currentFrame.landmark(.rightShoulder) else { return 0.0 }
        
        // Calculate shoulder line angle relative to setup
        let shoulderVector = CGPoint(x: rightShoulder.x - leftShoulder.x, y: rightShoulder.y - leftShoulder.y)
        let shoulderAngle = atan2(shoulderVector.y, shoulderVector.x) * 180 / .pi
        
        // Compare to address position (stored at swing start)
        // Ideal: 90° turn at top of backswing
        return abs(shoulderAngle)
    }
    
    func calculateHipRotationAngle() -> Double {
        guard let currentFrame = poseHistory.last,
              let leftHip = currentFrame.landmark(.leftHip),
              let rightHip = currentFrame.landmark(.rightHip) else { return 0.0 }
        
        // Calculate hip line angle
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        let hipAngle = atan2(hipVector.y, hipVector.x) * 180 / .pi
        
        // Ideal: 45° turn at top of backswing, hips lead in downswing
        return abs(hipAngle)
    }
    
    func calculateSpineAngle() -> Double {
        guard let currentFrame = poseHistory.last,
              let nose = currentFrame.landmark(.nose),
              let midHip = calculateMidHip(frame: currentFrame) else { return 0.0 }
        
        // Calculate spine tilt from vertical
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        let spineAngle = atan2(spineVector.x, spineVector.y) * 180 / .pi
        
        // Ideal: Maintain consistent spine angle throughout swing
        return abs(spineAngle)
    }
    
    func calculateWeightDistribution() -> (frontFoot: Double, backFoot: Double) {
        guard let currentFrame = poseHistory.last,
              let leftAnkle = currentFrame.landmark(.leftAnkle),
              let rightAnkle = currentFrame.landmark(.rightAnkle),
              let centerOfMass = calculateCenterOfMass(frame: currentFrame) else { 
            return (frontFoot: 50.0, backFoot: 50.0) 
        }
        
        // Calculate weight distribution based on center of mass relative to feet
        let totalWidth = abs(rightAnkle.x - leftAnkle.x)
        let leftWeight = abs(centerOfMass.x - leftAnkle.x) / totalWidth * 100
        let rightWeight = 100 - leftWeight
        
        // For right-handed golfer: left = front foot, right = back foot
        return (frontFoot: leftWeight, backFoot: rightWeight)
    }
    
    func calculateClubheadSpeed() -> Double {
        guard poseHistory.count >= 2 else { return 0.0 }
        
        let maxVelocity = poseHistory.suffix(10).compactMap { frame -> Double? in
            guard frame.landmark(.leftWrist) != nil else { return nil }
            return calculateWristVelocityForFrame(frame).magnitude
        }.max() ?? 0.0
        
        // Convert wrist velocity to estimated clubhead speed (rough approximation)
        // Clubhead is ~3x faster than wrists due to lever effect
        return maxVelocity * 150.0 // Scale to mph
    }
    
    func calculateSwingPlane() -> Double {
        guard let currentFrame = poseHistory.last,
              let leftShoulder = currentFrame.landmark(.leftShoulder),
              let rightShoulder = currentFrame.landmark(.rightShoulder),
              let leftWrist = currentFrame.landmark(.leftWrist) else {
            return 0.0
        }
        
        // Calculate swing plane angle based on shoulder line and wrist position
        let shoulderVector = CGVector(
            dx: rightShoulder.x - leftShoulder.x,
            dy: rightShoulder.y - leftShoulder.y
        )
        
        let wristVector = CGVector(
            dx: leftWrist.x - leftShoulder.x,
            dy: leftWrist.y - leftShoulder.y
        )
        
        // Calculate angle between vectors
        let dotProduct = shoulderVector.dx * wristVector.dx + shoulderVector.dy * wristVector.dy
        let shoulderMagnitude = sqrt(shoulderVector.dx * shoulderVector.dx + shoulderVector.dy * shoulderVector.dy)
        let wristMagnitude = sqrt(wristVector.dx * wristVector.dx + wristVector.dy * wristVector.dy)
        
        let cosAngle = dotProduct / (shoulderMagnitude * wristMagnitude)
        let angleRadians = acos(max(-1, min(1, cosAngle)))
        
        return angleRadians * 180.0 / .pi // Convert to degrees
    }
    
    func classifySwingPosition() -> String {
        guard let _ = poseHistory.last else { return "Unknown" }
        
        // Enhanced P-system classification
        let shoulderTurn = calculateShoulderTurnAngle()
        let hipTurn = calculateHipRotationAngle()
        let wristPosition = getCurrentWristPosition()
        
        // P1: Address (minimal movement)
        if shoulderTurn < 10 && hipTurn < 5 {
            return "P1-Address"
        }
        
        // P2-P3: Takeaway/Halfway Back
        if shoulderTurn < 45 && wristPosition < 0.3 {
            return shoulderTurn < 20 ? "P2-Takeaway" : "P3-Halfway-Back"
        }
        
        // P4: Top of Backswing
        if shoulderTurn > 70 && wristPosition > 0.7 {
            return "P4-Top"
        }
        
        // P5-P6: Downswing
        if shoulderTurn > 30 && wristPosition > 0.4 && isDownswing() {
            return wristPosition > 0.6 ? "P5-Early-Downswing" : "P6-Pre-Impact"
        }
        
        // P7: Impact
        if abs(wristPosition - 0.5) < 0.1 && hipTurn > 20 {
            return "P7-Impact"
        }
        
        // P8-P10: Follow Through
        if shoulderTurn > 80 && wristPosition < 0.3 {
            return shoulderTurn > 120 ? "P10-Finish" : "P8-Release"
        }
        
        return "P-Transition"
    }
    
    // MARK: - Helper Methods
    
    private func calculateMidHip(frame: PoseFrame) -> CGPoint? {
        guard let leftHip = frame.landmark(.leftHip),
              let rightHip = frame.landmark(.rightHip) else { return nil }
        
        return CGPoint(
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2
        )
    }
    
    private func calculateCenterOfMass(frame: PoseFrame) -> CGPoint? {
        // Simplified center of mass calculation using key body points
        guard let shoulders = calculateMidShoulder(frame: frame),
              let hips = calculateMidHip(frame: frame) else { return nil }
        
        // Weight center of mass between shoulders and hips
        return CGPoint(
            x: (shoulders.x + hips.x) / 2,
            y: (shoulders.y + hips.y) / 2
        )
    }
    
    private func calculateMidShoulder(frame: PoseFrame) -> CGPoint? {
        guard let leftShoulder = frame.landmark(.leftShoulder),
              let rightShoulder = frame.landmark(.rightShoulder) else { return nil }
        
        return CGPoint(
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2
        )
    }
    
    private func isDownswing() -> Bool {
        guard poseHistory.count >= 3 else { return false }
        
        // Check if wrist is moving downward (simplified detection)
        let recentFrames = poseHistory.suffix(3)
        let wristPositions = recentFrames.compactMap { $0.landmark(.leftWrist)?.y }
        
        guard wristPositions.count >= 2 else { return false }
        
        // Downswing: wrist moving down (increasing Y)
        guard let last = wristPositions.last, let first = wristPositions.first else { return false }
        return last > first
    }
    
    private func getCurrentWristPosition() -> Double {
        guard let currentFrame = poseHistory.last,
              let leftWrist = currentFrame.landmark(.leftWrist) else { return 0.0 }
        
        // Return normalized wrist position (0.0 = bottom, 1.0 = top)
        return Double(1.0 - leftWrist.y) // Flip Y coordinate
    }
    
    private func calculateWristVelocityForFrame(_ frame: PoseFrame) -> CGVector {
        guard let frameIndex = poseHistory.firstIndex(where: { $0.timestamp == frame.timestamp }),
              frameIndex > 0 else { return CGVector.zero }
        
        let previousFrame = poseHistory[frameIndex - 1]
        
        guard let currentWrist = frame.landmark(.leftWrist),
              let previousWrist = previousFrame.landmark(.leftWrist) else {
            return CGVector.zero
        }
        
        let timeInterval = frame.timestamp.timeIntervalSince(previousFrame.timestamp)
        guard timeInterval > 0 else { return CGVector.zero }
        
        let dx = (currentWrist.x - previousWrist.x) / timeInterval
        let dy = (currentWrist.y - previousWrist.y) / timeInterval
        
        return CGVector(dx: dx, dy: dy)
    }
}
