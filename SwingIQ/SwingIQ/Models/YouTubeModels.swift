//
//  YouTubeModels.swift
//  SwingIQ
//
//  Created by Amp on 7/29/25.
//

import Foundation

// MARK: - YouTube API Response Models

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeVideo]
    let pageInfo: PageInfo?
    
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
}

struct YouTubeVideo: Codable, Identifiable {
    let videoId: VideoId
    let snippet: VideoSnippet
    
    // Identifiable conformance - use videoId as the id
    var id: String {
        return videoId.videoId
    }
    
    var thumbnailURL: String {
        return snippet.thumbnails.medium?.url ?? snippet.thumbnails.default.url
    }
    
    var youtubeURL: String {
        return "https://www.youtube.com/watch?v=\(id)"
    }
    
    struct VideoId: Codable {
        let videoId: String
    }
    
    // Custom coding keys to map JSON 'id' to 'videoId'
    enum CodingKeys: String, CodingKey {
        case videoId = "id"
        case snippet
    }
}

struct VideoSnippet: Codable {
    let title: String
    let description: String
    let channelTitle: String
    let publishedAt: String
    let thumbnails: Thumbnails
    
    struct Thumbnails: Codable {
        let `default`: Thumbnail
        let medium: Thumbnail?
        let high: Thumbnail?
        
        struct Thumbnail: Codable {
            let url: String
            let width: Int?
            let height: Int?
        }
    }
}

// MARK: - Golf-Specific YouTube Content Models

struct GolfYouTubeRecommendation: Identifiable, Codable {
    let id = UUID()
    let video: YouTubeVideo
    let relevanceScore: Double
    let improvementArea: ImprovementArea
    let reason: String
    
    enum ImprovementArea: String, CaseIterable, Codable {
        case backswing = "Backswing"
        case downswing = "Downswing"
        case impact = "Impact"
        case followThrough = "Follow Through"
        case setup = "Setup"
        case tempo = "Tempo"
        case balance = "Balance"
        case shortGame = "Short Game"
        case putting = "Putting"
        case driving = "Driving"
        case general = "General"
        
        var searchKeywords: [String] {
            switch self {
            case .backswing:
                return ["golf backswing drill", "golf backswing tips", "backswing fundamentals"]
            case .downswing:
                return ["golf downswing drill", "golf downswing tips", "downswing sequence"]
            case .impact:
                return ["golf impact position", "golf impact drill", "ball striking tips"]
            case .followThrough:
                return ["golf follow through", "golf finish position", "follow through drill"]
            case .setup:
                return ["golf setup position", "golf address position", "golf stance"]
            case .tempo:
                return ["golf tempo drill", "golf swing tempo", "golf rhythm"]
            case .balance:
                return ["golf balance drill", "golf weight shift", "golf stability"]
            case .shortGame:
                return ["golf short game", "golf chipping", "golf pitching"]
            case .putting:
                return ["golf putting drill", "putting tips", "putting technique"]
            case .driving:
                return ["golf driving tips", "golf driver swing", "golf distance"]
            case .general:
                return ["golf tips", "golf instruction", "golf lessons"]
            }
        }
    }
}

// MARK: - Search Query Builder

struct YouTubeSearchQuery {
    let keywords: [String]
    let maxResults: Int
    let order: SearchOrder
    let relevanceLanguage: String
    
    enum SearchOrder: String {
        case relevance = "relevance"
        case date = "date"
        case rating = "rating"
        case viewCount = "viewCount"
    }
    
    init(improvementArea: GolfYouTubeRecommendation.ImprovementArea, maxResults: Int = 10) {
        self.keywords = improvementArea.searchKeywords
        self.maxResults = maxResults
        self.order = .relevance
        self.relevanceLanguage = "en"
    }
    
    var searchTerm: String {
        return keywords.randomElement() ?? "golf tips"
    }
}
