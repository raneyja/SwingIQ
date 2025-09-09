//
//  SwingAnalyzerService.swift
//  SwingIQ
//
//  Service for managing swing analysis data and history
//

import Foundation
import SwiftUI

class SwingAnalyzerService: ObservableObject {
    @Published var analysisHistory: [SwingAnalysis] = []
    
    static let shared = SwingAnalyzerService()
    
    private init() {
        loadAnalysisHistory()
    }
    
    func addAnalysis(_ analysis: SwingAnalysis) {
        analysisHistory.append(analysis)
        saveAnalysisHistory()
    }
    
    func clearHistory() {
        analysisHistory.removeAll()
        saveAnalysisHistory()
    }
    
    private func saveAnalysisHistory() {
        // Save to UserDefaults or SwiftData as needed
        // For now, keeping in memory
    }
    
    private func loadAnalysisHistory() {
        // Load from UserDefaults or SwiftData as needed
        // For now, empty array
    }
}
