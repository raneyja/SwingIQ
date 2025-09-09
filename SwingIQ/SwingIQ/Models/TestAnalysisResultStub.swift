//
//  TestAnalysisResultStub.swift
//  SwingIQ
//
//  Stub replacement for TestAnalysisResult after MediaPipe test view removal
//

import Foundation

/// Stub replacement for TestAnalysisResult type that was removed with MediaPipe test views
struct TestAnalysisResult: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let score: Double
    let notes: String
    let keypointCount: Int
    let confidence: Double
    let processingTime: Double
    
    init(timestamp: Date = Date(), score: Double = 0.0, notes: String = "Test analysis disabled") {
        self.timestamp = timestamp
        self.score = score
        self.notes = notes
        self.keypointCount = 0
        self.confidence = 0.0
        self.processingTime = 0.0
    }
}
