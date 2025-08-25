//
//  MediaPipeService.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import AVFoundation
import UIKit
import MediaPipeTasksVision

class MediaPipeService: ObservableObject {
    @Published var isProcessing = false
    @Published var poseKeypoints: [CGPoint] = []
    @Published var confidenceScores: [Float] = []
    @Published var lastError: String?
    @Published var currentSwingPhase: SwingPhase = .unknown
    @Published var swingMetrics: SwingMetrics?
    
    var poseLandmarker: PoseLandmarker?
    private let resultProcessor = PoseLandmarkerResultProcessor()
    
    private let processingQueue = DispatchQueue(label: "mediapipe.processing", qos: .userInitiated)
    
    // Pose history for velocity and analysis
    private var poseHistory: [PoseFrame] = []
    private let maxHistoryFrames = 30 // ~1 second at 30fps
    
    // Track image size for coordinate correction
    private var lastProcessedImageSize: CGSize?
    
    // Swing timing
    private var swingStartTime: Date?
    private var lastPhaseTime: Date?
    private var phaseTimings: [SwingPhase: TimeInterval] = [:]
    
    // Golf swing specific pose landmarks
    enum GolfPoseLandmarks: Int, CaseIterable {
        case nose = 0
        case leftEyeInner = 1
        case leftEye = 2
        case leftEyeOuter = 3
        case rightEyeInner = 4
        case rightEye = 5
        case rightEyeOuter = 6
        case leftEar = 7
        case rightEar = 8
        case leftShoulder = 11
        case rightShoulder = 12
        case leftElbow = 13
        case rightElbow = 14
        case leftWrist = 15
        case rightWrist = 16
        case leftHip = 23
        case rightHip = 24
        case leftKnee = 25
        case rightKnee = 26
        case leftAnkle = 27
        case rightAnkle = 28
        
        var description: String {
            switch self {
            case .nose: return "Nose"
            case .leftEyeInner: return "Left Eye Inner"
            case .leftEye: return "Left Eye"
            case .leftEyeOuter: return "Left Eye Outer"
            case .rightEyeInner: return "Right Eye Inner"
            case .rightEye: return "Right Eye"
            case .rightEyeOuter: return "Right Eye Outer"
            case .leftEar: return "Left Ear"
            case .rightEar: return "Right Ear"
            case .leftShoulder: return "Left Shoulder"
            case .rightShoulder: return "Right Shoulder"
            case .leftElbow: return "Left Elbow"
            case .rightElbow: return "Right Elbow"
            case .leftWrist: return "Left Wrist"
            case .rightWrist: return "Right Wrist"
            case .leftHip: return "Left Hip"
            case .rightHip: return "Right Hip"
            case .leftKnee: return "Left Knee"
            case .rightKnee: return "Right Knee"
            case .leftAnkle: return "Left Ankle"
            case .rightAnkle: return "Right Ankle"
            }
        }
    }
    
    init() {
        print("🔧 MediaPipeService: Starting initialization...")
        loadMediaPipeModel()
        setupResultProcessor()
        print("🔧 MediaPipeService: Initialization completed. Error: \(lastError ?? "None")")
    }
    
    func loadMediaPipeModel() {
        // Wrap the entire model loading in a do-catch to prevent crashes
        do {
            guard let modelPath = Bundle.main.path(forResource: "pose_landmarker_full", ofType: "task") else {
                lastError = "MediaPipe model file not found. Please add pose_landmarker_full.task to your project."
                print("❌ CRITICAL: MediaPipe model file not found at path: pose_landmarker_full.task")
                print("❌ Check that the model file is included in the app bundle")
                return
            }
            
            // Verify model file exists and is readable
            guard FileManager.default.fileExists(atPath: modelPath) else {
                lastError = "MediaPipe model file exists but is not accessible: \(modelPath)"
                print("❌ CRITICAL: Model file not accessible: \(modelPath)")
                return
            }
            
            print("🔧 Loading MediaPipe model from: \(modelPath)")
            
            let options = PoseLandmarkerOptions()
            options.baseOptions.modelAssetPath = modelPath
            options.runningMode = .image
            options.minPoseDetectionConfidence = 0.7  // Increased from 0.5 to reduce false positives
            options.minPosePresenceConfidence = 0.7   // Increased from 0.5 to reduce false positives
            options.minTrackingConfidence = 0.7       // Increased from 0.5 to reduce false positives
            options.numPoses = 1
            
            poseLandmarker = try PoseLandmarker(options: options)
            print("✅ MediaPipe PoseLandmarker initialized successfully")
            lastError = nil // Clear any previous errors
        } catch {
            lastError = "Failed to initialize PoseLandmarker: \(error.localizedDescription)"
            print("❌ CRITICAL: Error initializing PoseLandmarker: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            poseLandmarker = nil // Ensure it's nil on failure
        }
    }
    
    private func setupResultProcessor() {
        resultProcessor.onResultReceived = { [weak self] result in
            DispatchQueue.main.async {
                self?.processPoseResults(result)
            }
        }
    }
    
    // Async wrapper for modern Swift concurrency
    func detectPose(in image: UIImage) async throws -> (keypoints: [CGPoint], confidence: [Float]) {
        return try await withCheckedThrowingContinuation { continuation in
            detectPose(in: image) { success in
                if success {
                    continuation.resume(returning: (keypoints: self.poseKeypoints, confidence: self.confidenceScores))
                } else {
                    let error = NSError(domain: "MediaPipeError", code: -1, userInfo: [NSLocalizedDescriptionKey: self.lastError ?? "Pose detection failed"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func detectPose(in image: UIImage, completion: @escaping (Bool) -> Void) {
        processingQueue.async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            guard let poseLandmarker = self.poseLandmarker else {
                self.lastError = "PoseLandmarker not initialized - check model file"
                print("❌ CRITICAL: PoseLandmarker not initialized")
                print("❌ Last initialization error: \(self.lastError ?? "Unknown error")")
                
                // Clear previous results
                self.poseKeypoints = []
                self.confidenceScores = []
                completion(false)
                return
            }
            
            // Use defer to ensure isProcessing is always reset
            defer { self.isProcessing = false }
            
            // Skip if already processing to prevent resource conflicts
            if self.isProcessing {
                print("⚠️ MediaPipe already processing, skipping frame")
                completion(false)
                return
            }
            
            self.isProcessing = true
            self.lastError = nil
            
            do {
                let mpImage = try MPImage(uiImage: image)
                
                // Add safety check for the image
                guard mpImage.width > 0 && mpImage.height > 0 else {
                    throw NSError(domain: "MediaPipeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image dimensions"])
                }
                
                // Track image size for coordinate correction
                self.lastProcessedImageSize = CGSize(width: mpImage.width, height: mpImage.height)
                
                let result = try poseLandmarker.detect(image: mpImage)
                self.processPoseResults(result)
                completion(true)
            } catch {
                self.lastError = "Pose detection failed: \(error.localizedDescription)"
                print("❌ Pose detection failed: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                
                // Clear previous results to avoid stale data
                self.poseKeypoints = []
                self.confidenceScores = []
                completion(false)
            }
        }
    }
    
    func detectPose(in sampleBuffer: CMSampleBuffer, completion: @escaping (Bool) -> Void) {
        processingQueue.async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            guard let poseLandmarker = self.poseLandmarker else {
                self.lastError = "PoseLandmarker not initialized"
                completion(false)
                return
            }
            
            // Use defer to ensure isProcessing is always reset
            defer { self.isProcessing = false }
            
            // Skip if already processing to prevent resource conflicts
            if self.isProcessing {
                completion(false)
                return
            }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                self.lastError = "Failed to get pixel buffer from sample buffer"
                completion(false)
                return
            }
            
            self.isProcessing = true
            self.lastError = nil
        
            do {
                let mpImage = try MPImage(pixelBuffer: pixelBuffer)
                
                // Track image size for coordinate correction
                self.lastProcessedImageSize = CGSize(width: mpImage.width, height: mpImage.height)
                
                let result = try poseLandmarker.detect(image: mpImage)
                self.processPoseResults(result)
                completion(true)
            } catch {
                self.lastError = "Pose detection failed: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    private func processPoseResults(_ result: PoseLandmarkerResult) {
        guard !result.landmarks.isEmpty else {
            lastError = "No pose landmarks detected"
            print("⚠️ No pose landmarks detected in frame")
            // Clear previous results to avoid stale data
            self.poseKeypoints = []
            self.confidenceScores = []
            return
        }
        
        print("🔍 Processing pose result with \(result.landmarks.count) poses")
        
        var keypoints: [CGPoint] = []
        var confidences: [Float] = []
        
        // Double-check array bounds before accessing
        guard result.landmarks.count > 0 else {
            print("❌ CRITICAL ERROR: landmarks array is empty after guard check")
            self.poseKeypoints = []
            self.confidenceScores = []
            return
        }
        
        // Process first detected pose
        let landmarks = result.landmarks[0]
        
        // Extract key landmarks for golf swing analysis
        let relevantIndices = [
            0,  // nose
            11, 12, // left/right shoulder  
            13, 14, // left/right elbow
            15, 16, // left/right wrist
            23, 24, // left/right hip
            25, 26, // left/right knee
            27, 28  // left/right ankle
        ]
        
        for index in relevantIndices {
            if index < landmarks.count {
                let landmark = landmarks[index]
                
                // MediaPipe provides both visibility and presence scores
                let visibility = landmark.visibility?.floatValue ?? 0.0  // Whether the landmark is visible (not occluded)
                let presence = landmark.presence?.floatValue ?? 0.0      // Whether the landmark is present in the image
                
                // Combine visibility and presence for a comprehensive confidence score
                // Use average instead of min for better confidence assessment
                let combinedConfidence = (visibility + presence) / 2.0
                
                // Relaxed threshold for better skeleton completeness
                if combinedConfidence > 0.5 && visibility > 0.4 && presence > 0.4 {
                    // De-letterbox the MediaPipe coordinates
                    let correctedPoint = self.unletterboxLandmark(
                        landmark: landmark,
                        imageWidth: lastProcessedImageSize?.width ?? 1920,
                        imageHeight: lastProcessedImageSize?.height ?? 1080
                    )
                    
                    // Basic bounds checking - allow full coordinate range
                    if correctedPoint.x >= 0.0 && correctedPoint.x <= 1.0 && 
                       correctedPoint.y >= 0.0 && correctedPoint.y <= 1.0 {
                        // Apply temporal smoothing for stable tracking
                        let smoothedPoint = applySmoothingToKeypoint(
                            newPoint: correctedPoint,
                            keypointIndex: index,
                            confidence: combinedConfidence
                        )
                        
                        keypoints.append(smoothedPoint)
                        confidences.append(Float(combinedConfidence))
                        print("✅ Keypoint \(index) added - x: \(String(format: "%.3f", smoothedPoint.x)), y: \(String(format: "%.3f", smoothedPoint.y)), conf: \(String(format: "%.3f", combinedConfidence))")
                    } else {
                        // Coordinates too close to edges or out of bounds
                        keypoints.append(CGPoint(x: 0, y: 0))
                        confidences.append(0.0)
                        print("❌ Keypoint \(index) near edge/out of bounds - x: \(correctedPoint.x), y: \(correctedPoint.y)")
                    }
                } else {
                    // Add placeholder for invisible/absent keypoints to maintain array consistency
                    keypoints.append(CGPoint(x: 0, y: 0))
                    confidences.append(0.0)
                    print("🔍 Keypoint \(index) filtered out - visibility: \(visibility), presence: \(presence)")
                }
            } else {
                print("⚠️ Landmark index \(index) out of bounds (total: \(landmarks.count))")
                // Add placeholder values to maintain consistency
                keypoints.append(CGPoint(x: 0, y: 0))
                confidences.append(0.0)
            }
        }
        
        self.poseKeypoints = keypoints
        self.confidenceScores = confidences
        
        print("🔍 Extracted \(keypoints.count) keypoints, \(confidences.count) confidence scores")
        
        // Store pose frame for analysis
        let frame = PoseFrame(
            keypoints: keypoints,
            confidences: confidences,
            timestamp: Date()
        )
        
        addPoseFrame(frame)
        analyzeSwing()
    }
    
    // MARK: - Golf Swing Analysis Helpers
    
    private func addPoseFrame(_ frame: PoseFrame) {
        poseHistory.append(frame)
        
        // Maintain history limit
        if poseHistory.count > maxHistoryFrames {
            poseHistory.removeFirst()
        }
    }
    
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
    
    private func calculateSwingMetrics() -> SwingMetrics {
        return SwingMetrics(
            tempo: calculateTempo(),
            balance: calculateBalance(),
            swingPathDeviation: calculateSwingPathDeviation()
        )
    }
    
    // MARK: - Enhanced Golf-Specific Analysis
    
    private func calculateShoulderTurnAngle() -> Double {
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
    
    private func calculateHipRotationAngle() -> Double {
        guard let currentFrame = poseHistory.last,
              let leftHip = currentFrame.landmark(.leftHip),
              let rightHip = currentFrame.landmark(.rightHip) else { return 0.0 }
        
        // Calculate hip line angle
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        let hipAngle = atan2(hipVector.y, hipVector.x) * 180 / .pi
        
        // Ideal: 45° turn at top of backswing, hips lead in downswing
        return abs(hipAngle)
    }
    
    private func calculateSpineAngle() -> Double {
        guard let currentFrame = poseHistory.last,
              let nose = currentFrame.landmark(.nose),
              let midHip = calculateMidHip(frame: currentFrame) else { return 0.0 }
        
        // Calculate spine tilt from vertical
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        let spineAngle = atan2(spineVector.x, spineVector.y) * 180 / .pi
        
        // Ideal: Maintain consistent spine angle throughout swing
        return abs(spineAngle)
    }
    
    private func calculateWeightDistribution() -> (frontFoot: Double, backFoot: Double) {
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
    
    private func classifySwingPosition() -> String {
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
    
    // MARK: - Temporal Smoothing for Tighter Tracking
    
    private var keypointHistory: [[CGPoint]] = Array(repeating: [], count: 13) // 13 keypoints we track
    private let smoothingHistoryFrames = 5 // Keep last 5 frames for smoothing
    
    private func applySmoothingToKeypoint(newPoint: CGPoint, keypointIndex: Int, confidence: Float) -> CGPoint {
        // Ensure we have enough history arrays
        while keypointHistory.count <= keypointIndex {
            keypointHistory.append([])
        }
        
        // Add new point to history
        keypointHistory[keypointIndex].append(newPoint)
        
        // Maintain history size
        if keypointHistory[keypointIndex].count > smoothingHistoryFrames {
            keypointHistory[keypointIndex].removeFirst()
        }
        
        // Apply weighted smoothing based on confidence and temporal consistency
        if keypointHistory[keypointIndex].count >= 2 {
            let history = keypointHistory[keypointIndex]
            
            // High confidence points need less smoothing
            let smoothingFactor = confidence > 0.9 ? 0.3 : 0.6
            
            // Calculate weighted average with recent frames
            var weightedX: Double = 0.0
            var weightedY: Double = 0.0
            var totalWeight: Double = 0.0
            
            for (i, point) in history.enumerated() {
                // Recent frames have higher weight
                let weight = Double(i + 1) * (confidence > 0.9 ? 1.2 : 0.8)
                weightedX += Double(point.x) * weight
                weightedY += Double(point.y) * weight
                totalWeight += weight
            }
            
            let smoothedX = weightedX / totalWeight
            let smoothedY = weightedY / totalWeight
            
            // Blend with current point
            let finalX = (Double(newPoint.x) * (1.0 - smoothingFactor)) + (smoothedX * smoothingFactor)
            let finalY = (Double(newPoint.y) * (1.0 - smoothingFactor)) + (smoothedY * smoothingFactor)
            
            return CGPoint(x: finalX, y: finalY)
        }
        
        return newPoint
    }
    
    private func calculateClubheadSpeed() -> Double {
        guard poseHistory.count >= 2 else { return 0.0 }
        
        let maxVelocity = poseHistory.suffix(10).compactMap { frame -> Double? in
            guard frame.landmark(.leftWrist) != nil else { return nil }
            return calculateWristVelocity().magnitude
        }.max() ?? 0.0
        
        // Convert wrist velocity to estimated clubhead speed (rough approximation)
        // Clubhead is ~3x faster than wrists due to lever effect
        return maxVelocity * 150.0 // Scale to mph
    }
    
    private func calculateSwingPlane() -> Double {
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
    
    func getSwingPhase() -> SwingPhase {
        return currentSwingPhase
    }
    
    func getSwingMetrics() -> SwingMetrics? {
        return swingMetrics
    }
    
    // MARK: - Coordinate Correction
    
    private func unletterboxLandmark(landmark: NormalizedLandmark, imageWidth: CGFloat, imageHeight: CGFloat) -> CGPoint {
        let side = max(imageWidth, imageHeight)
        let padX = (side - imageWidth) / 2   // 0 when the frame is landscape
        let padY = (side - imageHeight) / 2  // 0 when the frame is portrait
        
        // Landmarker coordinates in absolute pixel space of the square
        let absX = CGFloat(landmark.x) * side - padX
        let absY = CGFloat(landmark.y) * side - padY
        
        // Convert back to 0-1 in original image space
        let normalizedX = absX / imageWidth
        let normalizedY = absY / imageHeight
        
        // Debug unletterboxing for troubleshooting
        if abs(landmark.x - 0.5) < 0.2 || abs(landmark.y - 0.5) < 0.2 {
            print("🔧 UNLETTERBOX: img=\(imageWidth)x\(imageHeight), square=\(side), landmark=(\(landmark.x), \(landmark.y)) → normalized=(\(normalizedX), \(normalizedY))")
        }
        
        return CGPoint(x: normalizedX, y: normalizedY)
    }
}

// MARK: - MediaPipe Extensions

extension CGVector {
    var magnitude: Double {
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - MediaPipe Result Processor

class PoseLandmarkerResultProcessor: NSObject {
    var onResultReceived: ((PoseLandmarkerResult) -> Void)?
}

extension PoseLandmarkerResultProcessor: PoseLandmarkerLiveStreamDelegate {
    func poseLandmarker(
        _ poseLandmarker: PoseLandmarker,
        didFinishDetection result: PoseLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {
        guard let result = result else {
            print("Pose detection error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        onResultReceived?(result)
    }
}
