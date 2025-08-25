//
//  APIConfiguration.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation

class APIConfiguration {
    static let shared = APIConfiguration()
    
    private init() {}
    
    // MARK: - API Keys Configuration
    
    /// Google Gemini API Key
    /// You can set this in one of three ways:
    /// 1. Set the GEMINI_API_KEY environment variable
    /// 2. Add it to your Info.plist under "GeminiAPIKey"
    /// 3. Directly set it here (not recommended for production)
    var geminiAPIKey: String? {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            return envKey
        }
        
        // Try Info.plist
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String {
            return plistKey
        }
        
        // Fallback - replace with your API key or leave nil to require configuration
        return nil
    }
    
    /// YouTube Data API Key
    /// You can set this in one of three ways:
    /// 1. Set the YOUTUBE_API_KEY environment variable
    /// 2. Add it to your Info.plist under "YouTubeAPIKey"
    /// 3. Directly set it here (not recommended for production)
    var youtubeAPIKey: String? {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] {
            return envKey
        }
        
        // Try Info.plist
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "YouTubeAPIKey") as? String {
            return plistKey
        }
        
        // Fallback - replace with your API key or leave nil to require configuration
        return nil
    }
    
    // MARK: - Validation
    
    func validateConfiguration() -> ConfigurationResult {
        guard let geminiKey = geminiAPIKey, !geminiKey.isEmpty else {
            return .missingAPIKey("Gemini API key not configured. Please set GEMINI_API_KEY environment variable, add GeminiAPIKey to Info.plist, or configure in APIConfiguration.swift")
        }
        
        guard geminiKey != "your-gemini-api-key-here" else {
            return .invalidAPIKey("Please replace the placeholder API key with your actual Gemini API key")
        }
        
        guard let youtubeKey = youtubeAPIKey, !youtubeKey.isEmpty else {
            return .missingAPIKey("YouTube API key not configured. Please set YOUTUBE_API_KEY environment variable, add YouTubeAPIKey to Info.plist, or configure in APIConfiguration.swift")
        }
        
        guard youtubeKey != "your-youtube-api-key-here" else {
            return .invalidAPIKey("Please replace the placeholder API key with your actual YouTube API key")
        }
        
        return .valid
    }
}

enum ConfigurationResult {
    case valid
    case missingAPIKey(String)
    case invalidAPIKey(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        default:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .missingAPIKey(let message), .invalidAPIKey(let message):
            return message
        }
    }
}
