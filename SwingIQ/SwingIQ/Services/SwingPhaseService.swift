//
//  SwingPhaseService.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation
import CoreGraphics

/// Service responsible for detecting golf swing phases and calculating swing timing
class SwingPhaseService: ObservableObject {
    @Published var currentSwingPhase: SwingPhase = .unknown
    @Published var swingMetrics: SwingMetrics?
    
    // Swing timing
    private var swingStartTime: Date?
    private var lastPhaseTime: Date?
    private var phaseTimings: [SwingPhase: TimeInterval] = [:]
    
    // Pose history for analysis
    private var poseHistory: [PoseFrame] = []
    private let maxHistoryFrames = 30 // ~1 second at 30fps
    
    // MARK: - Public Interface
    
    func addPoseFrame(_ frame: PoseFrame) {
        poseHistory.append(frame)
        
        // Maintain history limit
        if poseHistory.count > maxHistoryFrames {
            poseHistory.removeFirst()
        }
        
        analyzeSwing()
    }
    
    func resetSwing() {
        currentSwingPhase = .unknown
        swingMetrics = nil
        resetSwingTiming()
        poseHistory.removeAll()
    }
    
    func getSwingPhase() -> SwingPhase {
        return currentSwingPhase
    }
    
    func getSwingMetrics() -> SwingMetrics? {
        return swingMetrics
    }
    
    // MARK: - Swing Analysis
    
    private func analyzeSwing() {
        guard !poseHistory.isEmpty else { return }
        
        let newPhase = detectSwingPhase()
        
        // Update phase if changed
        if newPhase != currentSwingPhase {
            updateSwingPhase(to: newPhase)
        }
        
        // Calculate metrics
        swingMetrics = calculateSwingMetrics()
    }
    
    private func updateSwingPhase(to newPhase: SwingPhase) {
        let now = Date()
        
        // Record timing
        if let lastTime = lastPhaseTime {
            phaseTimings[currentSwingPhase] = now.timeIntervalSince(lastTime)
        }
        
        lastPhaseTime = now
        
        // Start swing timing on takeaway
        if newPhase == .takeaway && swingStartTime == nil {
            swingStartTime = now
        }
        
        // Reset on return to address
        if newPhase == .address && currentSwingPhase != .address {
            resetSwingTiming()
        }
        
        currentSwingPhase = newPhase
    }
    
    private func resetSwingTiming() {
        swingStartTime = nil
        lastPhaseTime = nil
        phaseTimings.removeAll()
    }
    
    // MARK: - Phase Detection
    
    private func detectSwingPhase() -> SwingPhase {
        guard let currentFrame = poseHistory.last,
              let leftWrist = currentFrame.landmark(.leftWrist),
              let rightWrist = currentFrame.landmark(.rightWrist),
              let leftShoulder = currentFrame.landmark(.leftShoulder),
              let rightShoulder = currentFrame.landmark(.rightShoulder) else {
            return .unknown
        }
        
        // Use right-handed golfer as default (can be made configurable)
        let leadWrist = leftWrist // Lead hand for right-handed golfer
        _ = rightWrist // Trail hand for right-handed golfer (not used in current calculation)
        let shoulderCenter = CGPoint(
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2
        )
        
        // Calculate wrist position relative to shoulders
        let wristHeight = leadWrist.y - shoulderCenter.y
        let wristPosition = leadWrist.x - shoulderCenter.x
        
        // Get wrist velocity if we have history
        let wristVelocity = calculateWristVelocity()
        
        // Phase detection logic
        if abs(wristPosition) < 0.1 && abs(wristHeight) < 0.1 {
            return .address
        } else if wristPosition < -0.1 && wristHeight > -0.2 && wristVelocity.magnitude < 0.5 {
            return .takeaway
        } else if wristPosition < -0.2 && wristHeight < -0.1 {
            return .backswing
        } else if wristPosition < -0.1 && wristVelocity.magnitude > 1.0 && wristVelocity.dx > 0 {
            return .downswing
        } else if abs(wristPosition) < 0.15 && wristVelocity.magnitude > 2.0 {
            return .impact
        } else if wristPosition > 0.1 && wristHeight > 0 {
            return .followThrough
        } else if wristPosition > 0.2 && wristVelocity.magnitude < 0.3 {
            return .finish
        }
        
        return currentSwingPhase // Maintain current phase if unclear
    }
    
    // MARK: - Metrics Calculation
    
    private func calculateSwingMetrics() -> SwingMetrics {
        return SwingMetrics(
            tempo: calculateTempo(),
            balance: calculateBalance(),
            swingSpeed: 0.0, // TODO: Implement swing speed calculation
            swingPathDeviation: calculateSwingPathDeviation()
        )
    }
    
    private func calculateTempo() -> Double {
        guard let backswingTime = phaseTimings[.backswing],
              let downswingTime = phaseTimings[.downswing],
              downswingTime > 0 else {
            return 3.0 // Default ratio
        }
        
        return backswingTime / downswingTime
    }
    
    private func calculateBalance() -> Double {
        guard let currentFrame = poseHistory.last,
              let leftAnkle = currentFrame.landmark(.leftAnkle),
              let rightAnkle = currentFrame.landmark(.rightAnkle),
              let leftHip = currentFrame.landmark(.leftHip),
              let rightHip = currentFrame.landmark(.rightHip) else {
            return 0.5
        }
        
        // Calculate center of pressure between feet
        let footCenter = CGPoint(
            x: (leftAnkle.x + rightAnkle.x) / 2,
            y: (leftAnkle.y + rightAnkle.y) / 2
        )
        
        // Calculate hip center
        let hipCenter = CGPoint(
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2
        )
        
        // Balance score based on hip-foot alignment
        let lateralDeviation = abs(hipCenter.x - footCenter.x)
        let balanceScore = max(0, 1.0 - lateralDeviation * 5.0) // Scale deviation
        
        return balanceScore
    }
    
    private func calculateSwingPathDeviation() -> Double {
        guard poseHistory.count >= 10 else { return 0.0 }
        
        // Get frames during impact phase (highest velocity period)
        let impactFrames = poseHistory.suffix(10).filter { frame in
            guard frame.landmark(.leftWrist) != nil else { return false }
            let velocity = calculateVelocityForFrame(frame)
            return velocity.magnitude > 1.5 // High velocity indicates impact zone
        }
        
        guard impactFrames.count >= 3 else { return 0.0 }
        
        // Establish target line (ball to target direction)
        let targetLine = establishTargetLine()
        
        // Calculate club path during impact
        let clubPath = calculateClubPath(from: impactFrames)
        
        // Calculate deviation angle between target line and club path
        let deviationAngle = calculateDeviationAngle(targetLine: targetLine, clubPath: clubPath)
        
        // Convert to degrees and apply inside/outside convention
        // Negative = inside, Positive = outside
        return deviationAngle * 180.0 / .pi
    }
    
    // MARK: - Velocity & Path Analysis
    
    private func calculateWristVelocity() -> CGVector {
        guard poseHistory.count >= 2 else { return CGVector.zero }
        
        guard let current = poseHistory.last else { return CGVector.zero }
        let previous = poseHistory[poseHistory.count - 2]
        
        guard let currentWrist = current.landmark(.leftWrist),
              let previousWrist = previous.landmark(.leftWrist) else {
            return CGVector.zero
        }
        
        let timeInterval = current.timestamp.timeIntervalSince(previous.timestamp)
        guard timeInterval > 0 else { return CGVector.zero }
        
        let dx = (currentWrist.x - previousWrist.x) / timeInterval
        let dy = (currentWrist.y - previousWrist.y) / timeInterval
        
        return CGVector(dx: dx, dy: dy)
    }
    
    private func establishTargetLine() -> CGVector {
        // For video analysis, we'll use the golfer's setup position to establish target line
        // In a real implementation, this could be calibrated during setup
        guard let addressFrame = poseHistory.first(where: { _ in currentSwingPhase == .address }),
              let leftShoulder = addressFrame.landmark(.leftShoulder),
              let rightShoulder = addressFrame.landmark(.rightShoulder) else {
            // Default target line pointing forward (perpendicular to shoulder line)
            return CGVector(dx: 1.0, dy: 0.0)
        }
        
        // Target line is perpendicular to shoulder line
        let shoulderLine = CGVector(
            dx: rightShoulder.x - leftShoulder.x,
            dy: rightShoulder.y - leftShoulder.y
        )
        
        // Perpendicular vector (rotated 90 degrees)
        return CGVector(dx: -shoulderLine.dy, dy: shoulderLine.dx)
    }
    
    private func calculateClubPath(from frames: [PoseFrame]) -> CGVector {
        guard frames.count >= 2 else { return CGVector.zero }
        
        // Use wrist movement to approximate club path during impact
        guard let firstFrame = frames.first, let lastFrame = frames.last else { return CGVector.zero }
        
        guard let firstWrist = firstFrame.landmark(.leftWrist),
              let lastWrist = lastFrame.landmark(.leftWrist) else {
            return CGVector.zero
        }
        
        // Club path vector from start to end of impact zone
        return CGVector(
            dx: lastWrist.x - firstWrist.x,
            dy: lastWrist.y - firstWrist.y
        )
    }
    
    private func calculateDeviationAngle(targetLine: CGVector, clubPath: CGVector) -> Double {
        // Calculate angle between target line and club path
        let dotProduct = targetLine.dx * clubPath.dx + targetLine.dy * clubPath.dy
        let targetMagnitude = sqrt(targetLine.dx * targetLine.dx + targetLine.dy * targetLine.dy)
        let clubMagnitude = sqrt(clubPath.dx * clubPath.dx + clubPath.dy * clubPath.dy)
        
        guard targetMagnitude > 0 && clubMagnitude > 0 else { return 0.0 }
        
        let cosAngle = dotProduct / (targetMagnitude * clubMagnitude)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        // Calculate cross product to determine inside/outside
        let crossProduct = targetLine.dx * clubPath.dy - targetLine.dy * clubPath.dx
        
        let angle = acos(clampedCosAngle)
        
        // Apply sign convention: negative for inside, positive for outside
        return crossProduct >= 0 ? angle : -angle
    }
    
    private func calculateVelocityForFrame(_ frame: PoseFrame) -> CGVector {
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

// MARK: - Extensions

extension CGVector {
    var magnitude: Double {
        return sqrt(dx * dx + dy * dy)
    }
}
