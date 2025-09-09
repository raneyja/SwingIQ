//
//  YouTubeRecommendationService.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation

class YouTubeRecommendationService: ObservableObject {
    private let youtubeService: YouTubeService?
    
    init() {
        // YouTube service is optional - if no API key, disable YouTube recommendations
        if let youtubeAPIKey = APIConfiguration.shared.youtubeAPIKey {
            self.youtubeService = YouTubeService(apiKey: youtubeAPIKey)
        } else {
            self.youtubeService = nil
            print("⚠️ YouTube recommendations disabled: No YouTube API key configured")
        }
    }
    
    // MARK: - Public Methods
    
    func getYouTubeRecommendations(for analysis: GeminiSwingFeedback) async -> [GolfYouTubeRecommendation] {
        guard let youtubeService = youtubeService else {
            print("ℹ️ YouTube recommendations disabled: No YouTube API key configured")
            return []
        }
        
        var recommendations: [GolfYouTubeRecommendation] = []
        
        let searchQueries = analysis.searchKeywords + analysis.improvements.map { improvement in
            "golf \(improvement) drill"
        }
        
        for query in Array(searchQueries.prefix(3)) {
            do {
                let videos = try await youtubeService.searchVideos(query: query, maxResults: 2)
                let golfRecommendations = videos.map { video in
                    GolfYouTubeRecommendation(
                        video: video,
                        relevanceScore: calculateRelevanceScore(query: query, video: video),
                        improvementArea: categorizeVideoToImprovementArea(from: query, video: video),
                        reason: generateRecommendationReason(from: query, video: video)
                    )
                }
                recommendations.append(contentsOf: golfRecommendations)
            } catch {
                print("YouTube search error for '\(query)': \(error)")
            }
        }
        
        return Array(recommendations.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(6))
    }
    
    func getRecommendationsForSearchTerms(_ searchTerms: [String]) async -> [GolfYouTubeRecommendation] {
        guard let youtubeService = youtubeService else {
            print("ℹ️ YouTube recommendations disabled: No YouTube API key configured")
            return []
        }
        
        var recommendations: [GolfYouTubeRecommendation] = []
        
        for query in Array(searchTerms.prefix(3)) {
            do {
                let videos = try await youtubeService.searchVideos(query: query, maxResults: 2)
                let golfRecommendations = videos.map { video in
                    GolfYouTubeRecommendation(
                        video: video,
                        relevanceScore: calculateRelevanceScore(query: query, video: video),
                        improvementArea: categorizeVideoToImprovementArea(from: query, video: video),
                        reason: generateRecommendationReason(from: query, video: video)
                    )
                }
                recommendations.append(contentsOf: golfRecommendations)
            } catch {
                print("YouTube search error for '\(query)': \(error)")
            }
        }
        
        return Array(recommendations.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(6))
    }
    
    // MARK: - Private Methods
    
    private func categorizeVideoToImprovementArea(from query: String, video: YouTubeVideo) -> GolfYouTubeRecommendation.ImprovementArea {
        let queryLower = query.lowercased()
        let titleLower = video.snippet.title.lowercased()
        
        if queryLower.contains("drill") || titleLower.contains("drill") || titleLower.contains("exercise") {
            return .general
        } else if queryLower.contains("swing plane") || titleLower.contains("swing plane") {
            return .backswing
        } else if queryLower.contains("tempo") || titleLower.contains("tempo") || titleLower.contains("rhythm") {
            return .tempo
        } else if queryLower.contains("balance") || titleLower.contains("balance") || titleLower.contains("weight shift") {
            return .balance
        } else if queryLower.contains("power") || titleLower.contains("power") || titleLower.contains("distance") {
            return .driving
        } else {
            return .general
        }
    }
    
    private func calculateRelevanceScore(query: String, video: YouTubeVideo) -> Double {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let titleWords = video.snippet.title.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let descriptionWords = video.snippet.description.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        var score = 0.0
        
        for queryWord in queryWords {
            if titleWords.contains(queryWord) {
                score += 2.0
            }
        }
        
        for queryWord in queryWords {
            if descriptionWords.contains(queryWord) {
                score += 1.0
            }
        }
        
        let golfChannels = ["Golf Digest", "PGA Tour", "Golf.com", "Rick Shiels Golf", "Me And My Golf", "Golf Monthly"]
        if golfChannels.contains(where: { video.snippet.channelTitle.contains($0) }) {
            score += 3.0
        }
        
        return score
    }
    
    private func generateRecommendationReason(from query: String, video: YouTubeVideo) -> String {
        return "This video addresses your \(query) needs based on your swing analysis."
    }
}
