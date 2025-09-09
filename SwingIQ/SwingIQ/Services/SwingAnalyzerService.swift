//
//  SwingAnalyzerService.swift
//  SwingIQ
//
//  Service for managing swing analysis data and history
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class SwingAnalyzerService {
    private var modelContext: ModelContext?
    var analysisHistory: [SwingAnalysis] = []
    
    static let shared = SwingAnalyzerService()
    
    private init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAnalysisHistory()
    }
    
    func addAnalysis(_ analysis: SwingAnalysis) {
        guard let modelContext = modelContext else { return }
        
        modelContext.insert(analysis)
        try? modelContext.save()
        
        analysisHistory.append(analysis)
    }
    
    func clearHistory() {
        guard let modelContext = modelContext else { return }
        
        try? modelContext.delete(model: SwingAnalysis.self)
        try? modelContext.save()
        
        analysisHistory.removeAll()
    }
    
    private func loadAnalysisHistory() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<SwingAnalysis>(sortBy: [SortDescriptor(\.timestamp)])
        analysisHistory = (try? modelContext.fetch(descriptor)) ?? []
    }
}
