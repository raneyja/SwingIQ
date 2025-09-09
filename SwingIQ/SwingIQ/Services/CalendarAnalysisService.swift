//
//  CalendarAnalysisService.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation
import EventKit

struct CalendarAnalysisResult {
    let isGolfRelated: Bool
    let confidence: Double
    let extractedCourseName: String?
    let extractedPlayerCount: Int?
    let golfType: GolfEventType?
    let recommendations: [String]
}

enum GolfEventType: String, CaseIterable {
    case teeTime = "Tee Time"
    case lesson = "Golf Lesson"
    case tournament = "Tournament"
    case practice = "Practice Session"
    case outing = "Golf Outing"
    case meeting = "Golf Meeting"
}

class CalendarAnalysisService: ObservableObject {
    private let geminiAPIKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
    
    init() {
        if let geminiAPIKey = APIConfiguration.shared.geminiAPIKey {
            self.geminiAPIKey = geminiAPIKey
        } else {
            print("⚠️ Gemini API key not configured - Calendar AI analysis features will be disabled")
            self.geminiAPIKey = ""
        }
    }
    
    // MARK: - Public Methods
    
    func analyzeCalendarEvent(_ event: EKEvent) async -> CalendarAnalysisResult {
        guard !geminiAPIKey.isEmpty else {
            print("ℹ️ Calendar AI analysis skipped - API key not configured, using fallback")
            return fallbackAnalysis(event)
        }
        
        let eventData = prepareEventData(event)
        
        do {
            let analysis = try await performAIAnalysis(eventData: eventData)
            return analysis
        } catch {
            print("AI Analysis error: \(error)")
            return fallbackAnalysis(event)
        }
    }
    
    // MARK: - Private Methods
    
    private func prepareEventData(_ event: EKEvent) -> [String: Any] {
        return [
            "title": event.title ?? "",
            "location": event.location ?? "",
            "notes": event.notes ?? "",
            "startDate": event.startDate.ISO8601Format(),
            "endDate": event.endDate.ISO8601Format(),
            "duration": event.endDate.timeIntervalSince(event.startDate)
        ]
    }
    
    private func performAIAnalysis(eventData: [String: Any]) async throws -> CalendarAnalysisResult {
        let prompt = createAnalysisPrompt(eventData: eventData)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 500,
                "topP": 0.8,
                "topK": 10
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(geminiAPIKey)") else {
            throw AIAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = response.candidates.first?.content.parts.first?.text else {
            throw AIAnalysisError.noResponse
        }
        
        return try parseAnalysisResponse(content)
    }
    
    private func createAnalysisPrompt(eventData: [String: Any]) -> String {
        return """
        You are an expert at analyzing calendar events to identify golf-related activities. Analyze this calendar event to determine if it's golf-related and extract relevant information:
        
        Event Details:
        - Title: \(eventData["title"] ?? "")
        - Location: \(eventData["location"] ?? "")
        - Notes: \(eventData["notes"] ?? "")
        - Start: \(eventData["startDate"] ?? "")
        - Duration: \(eventData["duration"] ?? 0) seconds
        
        Please analyze and return ONLY valid JSON with this exact format (no additional text):
        {
            "isGolfRelated": boolean,
            "confidence": number (0.0-1.0),
            "extractedCourseName": string or null,
            "extractedPlayerCount": number or null,
            "golfType": "Tee Time" | "Golf Lesson" | "Tournament" | "Practice Session" | "Golf Outing" | "Golf Meeting" | null,
            "recommendations": [string array of helpful suggestions]
        }
        
        Look for keywords like: golf, tee time, course, country club, driving range, putting, lesson, tournament, scramble, outing.
        Extract golf course names from location or title.
        Determine player count from phrases like "foursome", "2 players", etc.
        Provide recommendations for preparation or equipment needed.
        """
    }
    
    private func parseAnalysisResponse(_ content: String) throws -> CalendarAnalysisResult {
        // Clean the response to extract just the JSON part
        let cleanedContent = extractJSONFromResponse(content)
        
        guard let data = cleanedContent.data(using: .utf8) else {
            throw AIAnalysisError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw AIAnalysisError.invalidResponse
        }
        
        return CalendarAnalysisResult(
            isGolfRelated: json["isGolfRelated"] as? Bool ?? false,
            confidence: json["confidence"] as? Double ?? 0.0,
            extractedCourseName: json["extractedCourseName"] as? String,
            extractedPlayerCount: json["extractedPlayerCount"] as? Int,
            golfType: GolfEventType(rawValue: json["golfType"] as? String ?? ""),
            recommendations: json["recommendations"] as? [String] ?? []
        )
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // Remove any markdown code block markers
        let withoutCodeBlocks = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first { and last } to extract just the JSON
        guard let startIndex = withoutCodeBlocks.firstIndex(of: "{"),
              let endIndex = withoutCodeBlocks.lastIndex(of: "}") else {
            return withoutCodeBlocks
        }
        
        return String(withoutCodeBlocks[startIndex...endIndex])
    }
    
    private func fallbackAnalysis(_ event: EKEvent) -> CalendarAnalysisResult {
        let title = event.title?.lowercased() ?? ""
        let location = event.location?.lowercased() ?? ""
        let combinedText = "\(title) \(location)"
        
        let golfKeywords = ["golf", "tee", "course", "country club", "links"]
        let isGolfRelated = golfKeywords.contains { combinedText.contains($0) }
        
        return CalendarAnalysisResult(
            isGolfRelated: isGolfRelated,
            confidence: isGolfRelated ? 0.7 : 0.1,
            extractedCourseName: event.location,
            extractedPlayerCount: nil,
            golfType: isGolfRelated ? .teeTime : nil,
            recommendations: isGolfRelated ? ["Check weather conditions", "Prepare golf equipment"] : []
        )
    }
}
