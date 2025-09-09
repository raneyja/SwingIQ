//
//  AIAnalysisService.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//  Refactored by Amp on 8/26/25 - Split into focused services
//

import Foundation
import AVFoundation
import EventKit

// MARK: - Orchestration Service
class AIAnalysisService: ObservableObject {
    private let geminiAnalysisService: GeminiAnalysisService
    private let calendarAnalysisService: CalendarAnalysisService
    private let biomechanicsService: BiomechanicsService
    private let youtubeRecommendationService: YouTubeRecommendationService
    
    init() {
        self.geminiAnalysisService = GeminiAnalysisService()
        self.calendarAnalysisService = CalendarAnalysisService()
        self.biomechanicsService = BiomechanicsService()
        self.youtubeRecommendationService = YouTubeRecommendationService()
    }
    
    // Legacy initializer for backward compatibility
    convenience init(apiKey: String) {
        self.init()
    }
    
    // MARK: - Calendar Analysis
    
    func analyzeCalendarEvent(_ event: EKEvent) async -> CalendarAnalysisResult {
        return await calendarAnalysisService.analyzeCalendarEvent(event)
    }
    
    // MARK: - Video Analysis Methods
    
    func analyzeSwingWithGemini(_ analysisResult: VideoAnalysisResult, poseFrameData: [PoseFrameData]? = nil) async -> GeminiSwingAnalysis? {
        // Calculate biomechanics using dedicated service
        let biomechanics: [String: Any]
        if let poseFrameData = poseFrameData {
            biomechanics = biomechanicsService.calculateDetailedBiomechanics(from: poseFrameData)
        } else {
            biomechanics = [:]
        }
        
        // Get Gemini analysis
        guard let geminiResult = await geminiAnalysisService.analyzeSwing(analysisResult, poseFrameData: poseFrameData, biomechanics: biomechanics) else {
            return nil
        }
        
        // Get YouTube recommendations
        let geminiSwingFeedback = GeminiSwingFeedback(
            feedback: geminiResult.feedback,
            improvements: geminiResult.improvements,
            technicalTips: geminiResult.technicalTips,
            searchKeywords: geminiResult.technicalTips // Use technical tips as search keywords
        )
        let youtubeRecommendations = await youtubeRecommendationService.getYouTubeRecommendations(for: geminiSwingFeedback)
        
        return GeminiSwingAnalysis(
            feedback: geminiResult.feedback,
            improvements: geminiResult.improvements,
            technicalTips: geminiResult.technicalTips,
            youtubeRecommendations: youtubeRecommendations
        )
    }
    
    // MARK: - Testing Support
    #if DEBUG
    internal func performTestableProgression(_ frames: [PoseFrameData]) -> [String: Any] {
        return biomechanicsService.calculateDetailedBiomechanics(from: frames)
    }
    
    internal func sampleFramesForTesting(_ frames: [PoseFrameData], limit: Int) -> [PoseFrameData] {
        // This functionality would need to be moved to a utility service if needed
        guard frames.count > limit, limit > 0 else { return frames }
        let step = Double(frames.count - 1) / Double(limit - 1)
        return (0..<limit).map { frames[Int(round(Double($0) * step))] }
    }
    #endif
}

// MARK: - Supporting Types (keep for backward compatibility)
enum AIAnalysisError: Error {
    case invalidURL
    case noResponse
    case invalidResponse
}

struct GeminiSwingAnalysis {
    let feedback: String
    let improvements: [String]
    let technicalTips: [String]
    let youtubeRecommendations: [GolfYouTubeRecommendation]
}

struct GeminiSwingFeedback {
    let feedback: String
    let improvements: [String]  // Keep as strings for compatibility, parse in UI
    let technicalTips: [String]
    let searchKeywords: [String]
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
    }
}
