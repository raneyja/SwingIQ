//
//  YouTubeService.swift
//  SwingIQ
//
//  Created by Amp on 7/29/25.
//

import Foundation

class YouTubeService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://www.googleapis.com/youtube/v3/search"
    private let session = URLSession.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    /// Search for golf improvement videos based on specific areas
    func searchGolfVideos(for improvementArea: GolfYouTubeRecommendation.ImprovementArea) async throws -> [YouTubeVideo] {
        let query = YouTubeSearchQuery(improvementArea: improvementArea)
        return try await performSearch(query: query)
    }
    
    /// Search for videos with custom search terms
    func searchVideos(query: String, maxResults: Int = 10) async throws -> [YouTubeVideo] {
        // Create a custom search query manually
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "order", value: "relevance"),
            URLQueryItem(name: "relevanceLanguage", value: "en"),
            URLQueryItem(name: "safeSearch", value: "strict"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw YouTubeServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw YouTubeServiceError.apiError(httpResponse.statusCode)
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return searchResponse.items
        } catch {
            throw YouTubeServiceError.decodingError(error)
        }
    }
    
    /// Get recommendations based on swing analysis faults
    func getRecommendationsForFaults(_ faults: [SwingFault]) async -> [GolfYouTubeRecommendation] {
        var recommendations: [GolfYouTubeRecommendation] = []
        
        for fault in faults.prefix(3) { // Limit to top 3 faults
            let improvementArea = mapFaultToImprovementArea(fault)
            
            do {
                let videos = try await searchGolfVideos(for: improvementArea)
                
                for video in videos.prefix(2) { // Top 2 videos per fault
                    let recommendation = GolfYouTubeRecommendation(
                        video: video,
                        relevanceScore: calculateRelevanceScore(video: video, fault: fault),
                        improvementArea: improvementArea,
                        reason: generateRecommendationReason(fault: fault, video: video)
                    )
                    recommendations.append(recommendation)
                }
            } catch {
                print("Failed to get recommendations for \(fault.type): \(error)")
            }
        }
        
        return recommendations.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    // MARK: - Private Methods
    
    private func performSearch(query: YouTubeSearchQuery) async throws -> [YouTubeVideo] {
        guard let url = buildSearchURL(query: query) else {
            throw YouTubeServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw YouTubeServiceError.apiError(httpResponse.statusCode)
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return searchResponse.items
        } catch {
            throw YouTubeServiceError.decodingError(error)
        }
    }
    
    private func buildSearchURL(query: YouTubeSearchQuery) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query.searchTerm),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: String(query.maxResults)),
            URLQueryItem(name: "order", value: query.order.rawValue),
            URLQueryItem(name: "relevanceLanguage", value: query.relevanceLanguage),
            URLQueryItem(name: "safeSearch", value: "strict"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        return components?.url
    }
    
    private func mapFaultToImprovementArea(_ fault: SwingFault) -> GolfYouTubeRecommendation.ImprovementArea {
        switch fault.type {
        case .posture:
            return .setup
        case .swingPlane:
            if fault.description.contains("backswing") {
                return .backswing
            } else if fault.description.contains("downswing") {
                return .downswing
            } else {
                return .general
            }
        case .tempo:
            return .tempo
        case .balance:
            return .balance
        }
    }
    
    private func calculateRelevanceScore(video: YouTubeVideo, fault: SwingFault) -> Double {
        let title = video.snippet.title.lowercased()
        let description = video.snippet.description.lowercased()
        let combinedText = "\(title) \(description)"
        
        var score = 0.5 // Base score
        
        // Boost score for relevant keywords
        let relevantKeywords = [
            fault.type.rawValue.lowercased(),
            fault.description.lowercased().components(separatedBy: " ")
        ].flatMap { $0 is String ? [$0 as! String] : $0 as! [String] }
        
        for keyword in relevantKeywords {
            if combinedText.contains(keyword) {
                score += 0.1
            }
        }
        
        // Boost score for popular golf instructors
        let popularInstructors = ["rick shiels", "mark crossfield", "me and my golf", "clay ballard", "dechambeau"]
        for instructor in popularInstructors {
            if combinedText.contains(instructor) {
                score += 0.2
                break
            }
        }
        
        // Boost score for drill/instruction content
        let instructionalKeywords = ["drill", "tip", "lesson", "instruction", "how to", "fix"]
        for keyword in instructionalKeywords {
            if combinedText.contains(keyword) {
                score += 0.1
            }
        }
        
        return min(score, 1.0) // Cap at 1.0
    }
    
    private func generateRecommendationReason(fault: SwingFault, video: YouTubeVideo) -> String {
        let improvementArea = mapFaultToImprovementArea(fault)
        return "This video addresses your \(improvementArea.rawValue.lowercased()) issues. \(fault.recommendation)"
    }
}

// MARK: - Error Handling

enum YouTubeServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case decodingError(Error)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid YouTube API URL"
        case .invalidResponse:
            return "Invalid response from YouTube API"
        case .apiError(let code):
            return "YouTube API error with status code: \(code)"
        case .decodingError(let error):
            return "Failed to decode YouTube response: \(error.localizedDescription)"
        case .noResults:
            return "No YouTube videos found for the search query"
        }
    }
}
