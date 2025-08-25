//
//  AIAnalysisServiceTests.swift
//  SwingIQTests
//
//  Created by Amp on 8/15/25.
//

import Testing
import Foundation
import EventKit
@testable import SwingIQ

struct AIAnalysisServiceTests {
    
    // MARK: - Test Initialization
    
    @Test func testInitialization() {
        let service = AIAnalysisService(apiKey: "test-api-key")
        // Service should initialize without error
        #expect(service != nil)
    }
    
    // MARK: - Test Event Data Preparation
    
    @Test func testPrepareEventDataWithCompleteEvent() {
        let service = AIAnalysisService(apiKey: "test-key")
        let mockEvent = MockEKEvent(
            title: "Golf Tee Time",
            location: "Pebble Beach Golf Links",
            notes: "Playing with John and Mike",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600) // 1 hour later
        )
        
        let eventData = service.prepareEventData(mockEvent)
        
        #expect(eventData["title"] as? String == "Golf Tee Time")
        #expect(eventData["location"] as? String == "Pebble Beach Golf Links")
        #expect(eventData["notes"] as? String == "Playing with John and Mike")
        #expect(eventData["duration"] as? TimeInterval == 3600)
    }
    
    @Test func testPrepareEventDataWithNilValues() {
        let service = AIAnalysisService(apiKey: "test-key")
        let mockEvent = MockEKEvent(
            title: nil,
            location: nil,
            notes: nil,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800)
        )
        
        let eventData = service.prepareEventData(mockEvent)
        
        #expect(eventData["title"] as? String == "")
        #expect(eventData["location"] as? String == "")
        #expect(eventData["notes"] as? String == "")
        #expect(eventData["duration"] as? TimeInterval == 1800)
    }
    
    // MARK: - Test JSON Extraction
    
    @Test func testExtractJSONFromResponseWithCleanJSON() {
        let service = AIAnalysisService(apiKey: "test-key")
        let response = """
        {
            "isGolfRelated": true,
            "confidence": 0.95,
            "extractedCourseName": "Augusta National",
            "extractedPlayerCount": 4,
            "golfType": "Tee Time",
            "recommendations": ["Bring sunscreen", "Check dress code"]
        }
        """
        
        let cleanedJSON = service.extractJSONFromResponse(response)
        #expect(cleanedJSON.contains("isGolfRelated"))
        #expect(cleanedJSON.contains("Augusta National"))
    }
    
    @Test func testExtractJSONFromResponseWithMarkdown() {
        let service = AIAnalysisService(apiKey: "test-key")
        let response = """
        ```json
        {
            "isGolfRelated": false,
            "confidence": 0.1,
            "extractedCourseName": null,
            "extractedPlayerCount": null,
            "golfType": null,
            "recommendations": []
        }
        ```
        """
        
        let cleanedJSON = service.extractJSONFromResponse(response)
        #expect(!cleanedJSON.contains("```"))
        #expect(cleanedJSON.contains("isGolfRelated"))
    }
    
    @Test func testExtractJSONFromResponseWithExtraText() {
        let service = AIAnalysisService(apiKey: "test-key")
        let response = """
        Here is the analysis:
        
        {
            "isGolfRelated": true,
            "confidence": 0.8
        }
        
        This concludes the analysis.
        """
        
        let cleanedJSON = service.extractJSONFromResponse(response)
        #expect(cleanedJSON == "{\"isGolfRelated\": true,\"confidence\": 0.8}")
    }
    
    // MARK: - Test Response Parsing
    
    @Test func testParseAnalysisResponseSuccess() throws {
        let service = AIAnalysisService(apiKey: "test-key")
        let jsonResponse = """
        {
            "isGolfRelated": true,
            "confidence": 0.95,
            "extractedCourseName": "Torrey Pines",
            "extractedPlayerCount": 4,
            "golfType": "Tee Time",
            "recommendations": ["Arrive 30 minutes early", "Bring extra balls"]
        }
        """
        
        let result = try service.parseAnalysisResponse(jsonResponse)
        
        #expect(result.isGolfRelated == true)
        #expect(result.confidence == 0.95)
        #expect(result.extractedCourseName == "Torrey Pines")
        #expect(result.extractedPlayerCount == 4)
        #expect(result.golfType == .teeTime)
        #expect(result.recommendations.count == 2)
        #expect(result.recommendations.contains("Arrive 30 minutes early"))
    }
    
    @Test func testParseAnalysisResponseWithNullValues() throws {
        let service = AIAnalysisService(apiKey: "test-key")
        let jsonResponse = """
        {
            "isGolfRelated": false,
            "confidence": 0.2,
            "extractedCourseName": null,
            "extractedPlayerCount": null,
            "golfType": null,
            "recommendations": []
        }
        """
        
        let result = try service.parseAnalysisResponse(jsonResponse)
        
        #expect(result.isGolfRelated == false)
        #expect(result.confidence == 0.2)
        #expect(result.extractedCourseName == nil)
        #expect(result.extractedPlayerCount == nil)
        #expect(result.golfType == nil)
        #expect(result.recommendations.isEmpty)
    }
    
    @Test func testParseAnalysisResponseInvalidJSON() {
        let service = AIAnalysisService(apiKey: "test-key")
        let invalidJSON = "not json at all"
        
        #expect(throws: AIAnalysisError.invalidResponse) {
            try service.parseAnalysisResponse(invalidJSON)
        }
    }
    
    @Test func testParseAnalysisResponseMalformedJSON() {
        let service = AIAnalysisService(apiKey: "test-key")
        let malformedJSON = """
        {
            "isGolfRelated": true,
            "confidence": 0.5,
            // missing closing brace
        """
        
        #expect(throws: Error.self) {
            try service.parseAnalysisResponse(malformedJSON)
        }
    }
    
    // MARK: - Test Fallback Analysis
    
    @Test func testFallbackAnalysisGolfRelated() {
        let service = AIAnalysisService(apiKey: "test-key")
        let golfEvent = MockEKEvent(
            title: "Tee Time at Country Club",
            location: "Pine Valley Golf Course",
            notes: nil,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        
        let result = service.fallbackAnalysis(golfEvent)
        
        #expect(result.isGolfRelated == true)
        #expect(result.confidence == 0.7)
        #expect(result.extractedCourseName == "Pine Valley Golf Course")
        #expect(result.golfType == .teeTime)
        #expect(result.recommendations.contains("Check weather conditions"))
    }
    
    @Test func testFallbackAnalysisNonGolfEvent() {
        let service = AIAnalysisService(apiKey: "test-key")
        let nonGolfEvent = MockEKEvent(
            title: "Team Meeting",
            location: "Conference Room A",
            notes: nil,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800)
        )
        
        let result = service.fallbackAnalysis(nonGolfEvent)
        
        #expect(result.isGolfRelated == false)
        #expect(result.confidence == 0.1)
        #expect(result.extractedCourseName == "Conference Room A")
        #expect(result.golfType == nil)
        #expect(result.recommendations.isEmpty)
    }
    
    @Test func testFallbackAnalysisWithGolfKeywords() {
        let service = AIAnalysisService(apiKey: "test-key")
        
        let golfKeywords = ["golf", "tee", "course", "country club", "links"]
        
        for keyword in golfKeywords {
            let event = MockEKEvent(
                title: "Event with \(keyword)",
                location: nil,
                notes: nil,
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600)
            )
            
            let result = service.fallbackAnalysis(event)
            #expect(result.isGolfRelated == true, "Event with keyword '\(keyword)' should be detected as golf-related")
        }
    }
    
    // MARK: - Test Golf Event Types
    
    @Test func testGolfEventTypeEnumValues() {
        #expect(GolfEventType.teeTime.rawValue == "Tee Time")
        #expect(GolfEventType.lesson.rawValue == "Golf Lesson")
        #expect(GolfEventType.tournament.rawValue == "Tournament")
        #expect(GolfEventType.practice.rawValue == "Practice Session")
        #expect(GolfEventType.outing.rawValue == "Golf Outing")
        #expect(GolfEventType.meeting.rawValue == "Golf Meeting")
    }
    
    @Test func testGolfEventTypeFromString() {
        #expect(GolfEventType(rawValue: "Tee Time") == .teeTime)
        #expect(GolfEventType(rawValue: "Golf Lesson") == .lesson)
        #expect(GolfEventType(rawValue: "Invalid Type") == nil)
    }
    
    // MARK: - Test Error Handling
    
    @Test func testAIAnalysisErrorTypes() {
        let invalidURL = AIAnalysisError.invalidURL
        let noResponse = AIAnalysisError.noResponse
        let invalidResponse = AIAnalysisError.invalidResponse
        
        // Verify error types exist
        #expect(invalidURL != nil)
        #expect(noResponse != nil)
        #expect(invalidResponse != nil)
    }
    
    // MARK: - Test Calendar Analysis Result
    
    @Test func testCalendarAnalysisResultInitialization() {
        let result = CalendarAnalysisResult(
            isGolfRelated: true,
            confidence: 0.85,
            extractedCourseName: "St. Andrews",
            extractedPlayerCount: 2,
            golfType: .tournament,
            recommendations: ["Practice putting", "Arrive early"]
        )
        
        #expect(result.isGolfRelated == true)
        #expect(result.confidence == 0.85)
        #expect(result.extractedCourseName == "St. Andrews")
        #expect(result.extractedPlayerCount == 2)
        #expect(result.golfType == .tournament)
        #expect(result.recommendations.count == 2)
    }
}

// MARK: - Mock Classes

class MockEKEvent: EKEvent {
    private let _title: String?
    private let _location: String?
    private let _notes: String?
    private let _startDate: Date
    private let _endDate: Date
    
    init(title: String?, location: String?, notes: String?, startDate: Date, endDate: Date) {
        self._title = title
        self._location = location
        self._notes = notes
        self._startDate = startDate
        self._endDate = endDate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var title: String? { 
        get { return _title }
        set { /* Ignore setter */ }
    }
    override var location: String? { 
        get { return _location }
        set { /* Ignore setter */ }
    }
    override var notes: String? { 
        get { return _notes }
        set { /* Ignore setter */ }
    }
    override var startDate: Date! { 
        get { return _startDate }
        set { /* Ignore setter */ }
    }
    override var endDate: Date! { 
        get { return _endDate }
        set { /* Ignore setter */ }
    }
}

// MARK: - Extension for Testing Private Methods

extension AIAnalysisService {
    func prepareEventData(_ event: EKEvent) -> [String: Any] {
        return self.prepareEventData(event)
    }
    
    func extractJSONFromResponse(_ response: String) -> String {
        return self.extractJSONFromResponse(response)
    }
    
    func parseAnalysisResponse(_ content: String) throws -> CalendarAnalysisResult {
        return try self.parseAnalysisResponse(content)
    }
    
    func fallbackAnalysis(_ event: EKEvent) -> CalendarAnalysisResult {
        return self.fallbackAnalysis(event)
    }
}
