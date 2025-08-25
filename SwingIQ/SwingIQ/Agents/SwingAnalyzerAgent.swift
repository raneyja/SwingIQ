//
//  SwingAnalyzerAgent.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import CoreML
import Vision
import SwiftUI

class SwingAnalyzerAgent: ObservableObject {
    @Published var currentAnalysis: SwingAnalysis?
    @Published var analysisHistory: [SwingAnalysis] = []
    @Published var isAnalyzing = false
    @Published var recommendations: [SwingRecommendation] = []
    
    private let mediaPipeService: MediaPipeService
    private let swingDatabase: SwingDatabase
    private var aiAnalysisService: AIAnalysisService?
    
    init(mediaPipeService: MediaPipeService = MediaPipeService()) {
        self.mediaPipeService = mediaPipeService
        self.swingDatabase = SwingDatabase()
        
        // Initialize AI service with existing Gemini API key
        if let apiKey = APIConfiguration.shared.geminiAPIKey {
            self.aiAnalysisService = AIAnalysisService(apiKey: apiKey)
        }
        
        loadAnalysisHistory()
    }
    
    // MARK: - Real-time Analysis
    
    func analyzeSwingFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        
        mediaPipeService.detectPose(in: sampleBuffer) { [weak self] success in
            guard let self = self, success else {
                DispatchQueue.main.async {
                    self?.isAnalyzing = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.processPoseData()
                self.isAnalyzing = false
            }
        }
    }
    
    func analyzeCompleteSwing(frames: [CMSampleBuffer], completion: @escaping (SwingAnalysis?) -> Void) {
        guard !isAnalyzing else {
            completion(nil)
            return
        }
        
        isAnalyzing = true
        var poseSequence: [PoseFrame] = []
        let group = DispatchGroup()
        
        for (index, frame) in frames.enumerated() {
            group.enter()
            
            mediaPipeService.detectPose(in: frame) { success in
                if success {
                    let poseFrame = PoseFrame(
                        keypoints: self.mediaPipeService.poseKeypoints,
                        confidences: self.mediaPipeService.confidenceScores.isEmpty ? [] : self.mediaPipeService.confidenceScores,
                        timestamp: Date(timeIntervalSinceNow: Double(index) / 30.0) // Assuming 30 FPS
                    )
                    poseSequence.append(poseFrame)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let analysis = self.generateSwingAnalysis(from: poseSequence)
            self.currentAnalysis = analysis
            
            if let analysis = analysis {
                self.analysisHistory.append(analysis)
                self.saveAnalysisHistory()
                self.generateRecommendations(for: analysis)
            }
            
            self.isAnalyzing = false
            completion(analysis)
        }
    }
    
    // MARK: - Analysis Processing
    
    private func processPoseData() {
        // Get current pose keypoints and analysis
        let keypoints = mediaPipeService.poseKeypoints
        let confidences = mediaPipeService.confidenceScores
        
        guard !keypoints.isEmpty else { return }
        
        // Detect current swing phase
        let currentPhase = mediaPipeService.getSwingPhase()
        
        // Get swing metrics (now returns optional)
        let metrics = mediaPipeService.getSwingMetrics()
        
        // Create real-time analysis
        let analysis = SwingAnalysis(
            timestamp: Date(),
            phase: currentPhase,
            metrics: metrics ?? SwingMetrics(tempo: 0, balance: 0, swingPathDeviation: 0),
            keypoints: keypoints,
            confidenceScores: confidences,
            swingPhases: [:], // Real-time doesn't track full sequence
            faults: [],
            scores: SwingScores(overall: 0.5, tempo: 0.5, balance: 0.5),
            recommendations: []
        )
        
        currentAnalysis = analysis
        
        // Generate recommendations based on current state
        generateRecommendations(for: analysis)
        
        // Auto-save completed swings
        if currentPhase == .finish {
            self.swingDatabase.saveAnalysis(analysis)
        }
    }
    
    private func generateSwingAnalysis(from poseSequence: [PoseFrame]) -> SwingAnalysis? {
        guard !poseSequence.isEmpty else { return nil }
        
        let _ = detectSwingPhases(from: poseSequence)
        let faults = detectSwingFaults(from: poseSequence)
        let metrics = calculateSwingMetrics(from: poseSequence)
        let scores = calculateSwingScores(metrics: metrics, faults: faults)
        
        return SwingAnalysis(
            timestamp: Date(),
            phase: .followThrough,
            metrics: metrics,
            keypoints: poseSequence.last?.keypoints ?? [],
            confidenceScores: poseSequence.last?.confidences ?? [],
            swingPhases: [:], // Convert swingPhases array to dictionary if needed
            faults: faults,
            scores: scores,
            recommendations: []
        )
    }
    
    // MARK: - Swing Phase Detection
    
    private func detectSwingPhases(from poseSequence: [PoseFrame]) -> [SwingPhaseData] {
        var phases: [SwingPhaseData] = []
        
        // Simple heuristic-based phase detection
        // In production, this would use machine learning models
        
        let totalFrames = poseSequence.count
        let addressFrames = Int(Double(totalFrames) * 0.1)
        let backswingFrames = Int(Double(totalFrames) * 0.4)
        let downswingFrames = Int(Double(totalFrames) * 0.3)
        let impactFrames = Int(Double(totalFrames) * 0.05)
        let followThroughFrames = totalFrames - addressFrames - backswingFrames - downswingFrames - impactFrames
        
        var currentFrame = 0
        
        // Address
        phases.append(SwingPhaseData(
            phase: .address,
            startFrame: currentFrame,
            endFrame: currentFrame + addressFrames,
            duration: Double(addressFrames) / 30.0
        ))
        currentFrame += addressFrames
        
        // Backswing
        phases.append(SwingPhaseData(
            phase: .backswing,
            startFrame: currentFrame,
            endFrame: currentFrame + backswingFrames,
            duration: Double(backswingFrames) / 30.0
        ))
        currentFrame += backswingFrames
        
        // Downswing
        phases.append(SwingPhaseData(
            phase: .downswing,
            startFrame: currentFrame,
            endFrame: currentFrame + downswingFrames,
            duration: Double(downswingFrames) / 30.0
        ))
        currentFrame += downswingFrames
        
        // Impact
        phases.append(SwingPhaseData(
            phase: .impact,
            startFrame: currentFrame,
            endFrame: currentFrame + impactFrames,
            duration: Double(impactFrames) / 30.0
        ))
        currentFrame += impactFrames
        
        // Follow Through
        phases.append(SwingPhaseData(
            phase: .followThrough,
            startFrame: currentFrame,
            endFrame: totalFrames,
            duration: Double(followThroughFrames) / 30.0
        ))
        
        return phases
    }
    
    // MARK: - Fault Detection
    
    private func detectSwingFaults(from poseSequence: [PoseFrame]) -> [SwingFault] {
        var faults: [SwingFault] = []
        
        // Check for common swing faults
        faults.append(contentsOf: checkPostureFaults(poseSequence))
        faults.append(contentsOf: checkSwingPlaneFaults(poseSequence))
        faults.append(contentsOf: checkSwingPathFaults(poseSequence)) // NEW: Swing path analysis
        faults.append(contentsOf: checkTempoFaults(poseSequence))
        faults.append(contentsOf: checkBalanceFaults(poseSequence))
        
        return faults
    }
    
    private func checkPostureFaults(_ poseSequence: [PoseFrame]) -> [SwingFault] {
        var faults: [SwingFault] = []
        
        // Check for slouched posture
        // This is a simplified check - in production you'd have more sophisticated analysis
        let avgSpineAngle = calculateAverageSpineAngle(poseSequence)
        if avgSpineAngle < 20 {
            faults.append(SwingFault(
                id: UUID(),
                type: .posture,
                severity: .medium,
                description: "Slouched posture detected",
                recommendation: "Maintain a straighter spine throughout your swing"
            ))
        }
        
        return faults
    }
    
    private func checkSwingPlaneFaults(_ poseSequence: [PoseFrame]) -> [SwingFault] {
        var faults: [SwingFault] = []
        
        // Check for over-the-top swing
        let swingPlaneConsistency = calculateSwingPlaneConsistency(poseSequence)
        if swingPlaneConsistency < 0.7 {
            faults.append(SwingFault(
                id: UUID(),
                type: .swingPlane,
                severity: .high,
                description: "Inconsistent swing plane",
                recommendation: "Focus on maintaining a consistent swing plane throughout your swing"
            ))
        }
        
        return faults
    }
    
    private func checkTempoFaults(_ poseSequence: [PoseFrame]) -> [SwingFault] {
        var faults: [SwingFault] = []
        
        // Check for rushed tempo
        let tempoRatio = calculateTempoRatio(poseSequence)
        if tempoRatio < 2.0 {
            faults.append(SwingFault(
                id: UUID(),
                type: .tempo,
                severity: .medium,
                description: "Rushed tempo",
                recommendation: "Slow down your backswing for better tempo control"
            ))
        }
        
        return faults
    }
    
    private func checkBalanceFaults(_ poseSequence: [PoseFrame]) -> [SwingFault] {
        var faults: [SwingFault] = []
        
        // Check for weight shift issues
        let balanceScore = calculateBalanceScore(poseSequence)
        if balanceScore < 0.6 {
            faults.append(SwingFault(
                id: UUID(),
                type: .balance,
                severity: .medium,
                description: "Poor weight distribution",
                recommendation: "Work on maintaining better balance throughout your swing"
            ))
        }
        
        return faults
    }
    
    // MARK: - Metrics Calculation
    
    private func calculateSwingMetrics(from poseSequence: [PoseFrame]) -> SwingMetrics {
        return SwingMetrics(
            tempo: calculateTempoRatio(poseSequence),
            balance: calculateBalanceScore(poseSequence),
            swingPathDeviation: calculateSwingPathDeviation(poseSequence)
        )
    }
    
    private func calculateSwingScores(metrics: SwingMetrics, faults: [SwingFault]) -> SwingScores {
        // Calculate scores based on metrics and faults
        let balance = metrics.balance
        let tempo = min(1.0, (metrics.tempo / 3.0)) // 3:1 is ideal tempo
        let pathScore = max(0, 1.0 - metrics.swingPathDeviation) // Lower deviation is better
        let overall = (balance + tempo + pathScore) / 3.0
        
        return SwingScores(
            overall: overall,
            tempo: tempo,
            balance: balance
        )
    }
    
    // MARK: - Helper Calculations
    
    private func calculateAverageSpineAngle(_ poseSequence: [PoseFrame]) -> Double {
        // Simplified calculation - would be more sophisticated in production
        return 25.0
    }
    
    private func calculateSwingPlaneConsistency(_ poseSequence: [PoseFrame]) -> Double {
        // Simplified calculation
        return 0.8
    }
    
    private func calculateTempoRatio(_ poseSequence: [PoseFrame]) -> Double {
        // Simplified calculation
        return 2.8
    }
    
    private func calculateBalanceScore(_ poseSequence: [PoseFrame]) -> Double {
        // Simplified calculation
        return 0.75
    }
    
    private func calculateClubheadSpeed(_ poseSequence: [PoseFrame]) -> Double {
        // Estimate based on wrist velocity
        return 95.0
    }
    
    private func calculateSwingPlane(_ poseSequence: [PoseFrame]) -> Double {
        // Calculate swing plane angle
        return 45.0
    }
    
    private func calculateSwingPathDeviation(_ poseSequence: [PoseFrame]) -> Double {
        guard poseSequence.count >= 10 else { return 0.0 }
        
        // Find impact zone frames (highest velocity period)
        let impactFrames = findImpactFrames(in: poseSequence)
        guard impactFrames.count >= 3 else { return 0.0 }
        
        // Establish target line from address position
        let targetLine = establishTargetLine(from: poseSequence)
        
        // Calculate club path through impact
        let clubPath = calculateClubPath(from: impactFrames)
        
        // Calculate deviation angle
        return calculateDeviationAngle(targetLine: targetLine, clubPath: clubPath)
    }
    
    private func findImpactFrames(in poseSequence: [PoseFrame]) -> [PoseFrame] {
        // Look for frames with highest wrist velocity (impact zone)
        let velocityThreshold = 1.5
        
        return poseSequence.enumerated().compactMap { index, frame in
            guard index > 0,
                  let wrist = frame.landmark(.leftWrist),
                  let prevWrist = poseSequence[index - 1].landmark(.leftWrist) else {
                return nil
            }
            
            let timeInterval = frame.timestamp.timeIntervalSince(poseSequence[index - 1].timestamp)
            guard timeInterval > 0 else { return nil }
            
            let dx = (wrist.x - prevWrist.x) / timeInterval
            let dy = (wrist.y - prevWrist.y) / timeInterval
            let velocity = sqrt(dx * dx + dy * dy)
            
            return velocity > velocityThreshold ? frame : nil
        }
    }
    
    private func establishTargetLine(from poseSequence: [PoseFrame]) -> CGVector {
        // Use first frame (address position) to establish target line
        guard let addressFrame = poseSequence.first,
              let leftShoulder = addressFrame.landmark(.leftShoulder),
              let rightShoulder = addressFrame.landmark(.rightShoulder) else {
            return CGVector(dx: 1.0, dy: 0.0) // Default forward direction
        }
        
        // Target line perpendicular to shoulder line
        let shoulderLine = CGVector(
            dx: rightShoulder.x - leftShoulder.x,
            dy: rightShoulder.y - leftShoulder.y
        )
        
        // Perpendicular vector (90 degrees rotated)
        return CGVector(dx: -shoulderLine.dy, dy: shoulderLine.dx)
    }
    
    private func calculateClubPath(from impactFrames: [PoseFrame]) -> CGVector {
        guard impactFrames.count >= 2,
              let firstWrist = impactFrames.first?.landmark(.leftWrist),
              let lastWrist = impactFrames.last?.landmark(.leftWrist) else {
            return CGVector.zero
        }
        
        return CGVector(
            dx: lastWrist.x - firstWrist.x,
            dy: lastWrist.y - firstWrist.y
        )
    }
    
    private func calculateDeviationAngle(targetLine: CGVector, clubPath: CGVector) -> Double {
        let dotProduct = targetLine.dx * clubPath.dx + targetLine.dy * clubPath.dy
        let targetMagnitude = sqrt(targetLine.dx * targetLine.dx + targetLine.dy * targetLine.dy)
        let clubMagnitude = sqrt(clubPath.dx * clubPath.dx + clubPath.dy * clubPath.dy)
        
        guard targetMagnitude > 0 && clubMagnitude > 0 else { return 0.0 }
        
        let cosAngle = dotProduct / (targetMagnitude * clubMagnitude)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        // Cross product for direction (inside/outside)
        let crossProduct = targetLine.dx * clubPath.dy - targetLine.dy * clubPath.dx
        
        let angle = acos(clampedCosAngle) * 180.0 / .pi
        
        // Negative = inside, Positive = outside
        return crossProduct >= 0 ? angle : -angle
    }
    
    // NEW: Swing Path Fault Detection
    private func checkSwingPathFaults(_ poseSequence: [PoseFrame]) -> [SwingFault] {
        var faults: [SwingFault] = []
        
        let pathDeviation = calculateSwingPathDeviation(poseSequence)
        let absDeviation = abs(pathDeviation)
        
        // Check for severe inside-out swing path
        if pathDeviation < -8.0 {
            faults.append(SwingFault(
                id: UUID(),
                type: .swingPlane, // Using existing type, could add .swingPath if needed
                severity: .high,
                description: "Severe inside-out swing path (\(String(format: "%.1f", absDeviation))° inside)",
                recommendation: "Focus on bringing the club more on plane. Practice outside-in drills to correct this path."
            ))
        } else if pathDeviation < -4.0 {
            faults.append(SwingFault(
                id: UUID(),
                type: .swingPlane,
                severity: .medium,
                description: "Inside-out swing path (\(String(format: "%.1f", absDeviation))° inside)",
                recommendation: "Slightly too much inside-out. Work on a more neutral swing path for better accuracy."
            ))
        }
        
        // Check for severe outside-in swing path
        if pathDeviation > 8.0 {
            faults.append(SwingFault(
                id: UUID(),
                type: .swingPlane,
                severity: .high,
                description: "Severe outside-in swing path (\(String(format: "%.1f", absDeviation))° outside)",
                recommendation: "This path often causes slices. Focus on swinging more from the inside and rotating through impact."
            ))
        } else if pathDeviation > 4.0 {
            faults.append(SwingFault(
                id: UUID(),
                type: .swingPlane,
                severity: .medium,
                description: "Outside-in swing path (\(String(format: "%.1f", absDeviation))° outside)",
                recommendation: "Slightly too much outside-in. Work on approaching the ball more from the inside."
            ))
        }
        
        return faults
    }
    
    // MARK: - Recommendations
    
    private func generateRecommendations(for analysis: SwingAnalysis) {
        var newRecommendations: [SwingRecommendation] = []
        
        // Generate recommendations based on faults and scores
        for fault in analysis.faults {
            let recommendation = SwingRecommendation(
                title: "Fix \(fault.type.rawValue.capitalized) Issue",
                description: fault.recommendation,
                priority: SwingRecommendation.RecommendationPriority.medium
            )
            newRecommendations.append(recommendation)
        }
        
        // Add general recommendations based on scores
        if analysis.scores.overall < 70 {
            newRecommendations.append(SwingRecommendation(
                title: "Increase Power",
                description: "Focus on generating more clubhead speed through better rotation and lag",
                priority: SwingRecommendation.RecommendationPriority.medium
            ))
        }
        
        DispatchQueue.main.async {
            self.recommendations = newRecommendations
        }
    }
    
    private func getExercisesFor(fault: SwingFault) -> [String] {
        switch fault.type {
        case .posture:
            return ["Wall push-ups", "Spine alignment drills", "Core strengthening"]
        case .swingPlane:
            return ["Plane board drills", "Half swings", "Mirror work"]
        case .tempo:
            return ["Metronome practice", "Slow motion swings", "Count drills"]
        case .balance:
            return ["One-leg stands", "Balance board", "Weight shift drills"]
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadAnalysisHistory() {
        analysisHistory = swingDatabase.loadAnalysisHistory()
        
        // For testing: Add sample data if no real data exists
        if analysisHistory.isEmpty {
            generateSampleData()
        }
    }
    
    private func saveAnalysisHistory() {
        swingDatabase.saveAnalysisHistory(analysisHistory)
    }
    
    // MARK: - Sample Data Generation (for testing)
    
    private func generateSampleData() {
        let calendar = Calendar.current
        var sampleAnalyses: [SwingAnalysis] = []
        
        // Generate data for the last 30 days
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            
            // Random chance of having 1-3 sessions per day
            let sessionCount = Int.random(in: 0...3)
            
            for j in 0..<sessionCount {
                let sessionTime = calendar.date(byAdding: .hour, value: j * 2, to: date) ?? date
                
                let analysis = SwingAnalysis(
                    timestamp: sessionTime,
                    phase: .finish,
                    metrics: SwingMetrics(
                        tempo: Double.random(in: 2.5...3.5),
                        balance: Double.random(in: 0.6...0.95),
                        swingPathDeviation: Double.random(in: -6...6)
                    ),
                    keypoints: [],
                    confidenceScores: [],
                    swingPhases: [:],
                    faults: [],
                    scores: SwingScores(
                        overall: Double.random(in: 0.6...0.9),
                        tempo: Double.random(in: 0.6...0.9),
                        balance: Double.random(in: 0.6...0.9)
                    ),
                    recommendations: []
                )
                
                sampleAnalyses.append(analysis)
            }
        }
        
        analysisHistory = sampleAnalyses.sorted { $0.timestamp < $1.timestamp }
        saveAnalysisHistory()
    }
}

// MARK: - Database

class SwingDatabase {
    private let userDefaults = UserDefaults.standard
    private let analysisKey = "SwingAnalysisHistory"
    
    func loadAnalysisHistory() -> [SwingAnalysis] {
        guard let data = userDefaults.data(forKey: analysisKey),
              let analyses = try? JSONDecoder().decode([SwingAnalysis].self, from: data) else {
            return []
        }
        return analyses
    }
    
    func saveAnalysisHistory(_ analyses: [SwingAnalysis]) {
        guard let data = try? JSONEncoder().encode(analyses) else { return }
        userDefaults.set(data, forKey: analysisKey)
    }
    
    func saveAnalysis(_ analysis: SwingAnalysis) {
        var history = loadAnalysisHistory()
        history.append(analysis)
        saveAnalysisHistory(history)
    }
}


