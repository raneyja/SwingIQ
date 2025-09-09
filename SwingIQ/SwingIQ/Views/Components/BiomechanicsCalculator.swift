//
//  BiomechanicsCalculator.swift
//  SwingIQ
//
//  Enhanced biomechanics calculations separated from view logic
//

import SwiftUI

struct EnhancedBiomechanics {
    let elbowAngles: (left: Double, right: Double)
    let kneeFlexions: (left: Double, right: Double)
    let stanceMetrics: (width: Double, balance: Double)
}

class BiomechanicsCalculator {
    
    // MARK: - Main Calculation Method
    
    static func calculateEnhancedBiomechanics(frame: PoseFrameData) -> EnhancedBiomechanics {
        return EnhancedBiomechanics(
            elbowAngles: calculateElbowAngles(frame: frame),
            kneeFlexions: calculateKneeFlexion(frame: frame),
            stanceMetrics: calculateStanceMetrics(frame: frame)
        )
    }
    
    // MARK: - Elbow Angles
    
    static func calculateElbowAngles(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftElbow: Double = 0
        var rightElbow: Double = 0
        
        // Left elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count > 5,
           frame.confidence[1] > 0.8, // left shoulder
           frame.confidence[3] > 0.8, // left elbow
           frame.confidence[5] > 0.8 { // left wrist
            leftElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[1], // shoulder
                vertex: frame.keypoints[3], // elbow
                p3: frame.keypoints[5] // wrist
            )
        }
        
        // Right elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count > 6,
           frame.confidence[2] > 0.8, // right shoulder
           frame.confidence[4] > 0.8, // right elbow
           frame.confidence[6] > 0.8 { // right wrist
            rightElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[2], // shoulder
                vertex: frame.keypoints[4], // elbow
                p3: frame.keypoints[6] // wrist
            )
        }
        
        return (left: leftElbow, right: rightElbow)
    }
    
    // MARK: - Knee Flexions
    
    static func calculateKneeFlexion(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftKnee: Double = 0
        var rightKnee: Double = 0
        
        // Left knee flexion (hip-knee-ankle)
        if frame.keypoints.count > 11,
           frame.confidence[7] > 0.8, // left hip
           frame.confidence[9] > 0.8, // left knee
           frame.confidence[11] > 0.8 { // left ankle
            leftKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[7], // hip
                vertex: frame.keypoints[9], // knee
                p3: frame.keypoints[11] // ankle
            )
        }
        
        // Right knee flexion (hip-knee-ankle)
        if frame.keypoints.count > 12,
           frame.confidence[8] > 0.8, // right hip
           frame.confidence[10] > 0.8, // right knee
           frame.confidence[12] > 0.8 { // right ankle
            rightKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[8], // hip
                vertex: frame.keypoints[10], // knee
                p3: frame.keypoints[12] // ankle
            )
        }
        
        return (left: leftKnee, right: rightKnee)
    }
    
    // MARK: - Stance Metrics
    
    static func calculateStanceMetrics(frame: PoseFrameData) -> (width: Double, balance: Double) {
        guard frame.keypoints.count > 12,
              frame.confidence[11] > 0.8, // left ankle
              frame.confidence[12] > 0.8, // right ankle
              frame.confidence[7] > 0.8, // left hip
              frame.confidence[8] > 0.8 else { // right hip
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
    
    // MARK: - Basic Joint Angles
    
    static func calculateHipAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 8,
              frame.confidence[7] > 0.8, // left hip
              frame.confidence[8] > 0.8  // right hip
        else { return 0.0 }
        
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        return abs(atan2(hipVector.y, hipVector.x) * 180 / .pi)
    }
    
    static func calculateShoulderAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 2,
              frame.confidence[1] > 0.8, // left shoulder
              frame.confidence[2] > 0.8  // right shoulder
        else { return 0.0 }
        
        let leftShoulder = frame.keypoints[1]
        let rightShoulder = frame.keypoints[2]
        let shoulderVector = CGPoint(x: rightShoulder.x - leftShoulder.x, y: rightShoulder.y - leftShoulder.y)
        return abs(atan2(shoulderVector.y, shoulderVector.x) * 180 / .pi)
    }
    
    static func calculateSpineAngle(frame: PoseFrameData) -> Double {
        guard frame.keypoints.count > 8,
              frame.confidence[0] > 0.8, // nose
              frame.confidence[7] > 0.8, // left hip
              frame.confidence[8] > 0.8  // right hip
        else { return 0.0 }
        
        let nose = frame.keypoints[0]
        let midHip = CGPoint(
            x: (frame.keypoints[7].x + frame.keypoints[8].x) / 2,
            y: (frame.keypoints[7].y + frame.keypoints[8].y) / 2
        )
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        return abs(atan2(spineVector.x, spineVector.y) * 180 / .pi)
    }
    
    // MARK: - Helper Methods
    
    static func calculateAngleBetweenThreePoints(p1: CGPoint, vertex: CGPoint, p3: CGPoint) -> Double {
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
}
