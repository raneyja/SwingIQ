//
//  ExportModels.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import CoreGraphics

// MARK: - Export Data Models

/// Supported export formats
enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF"
    case detailed = "Detailed Report"
    
    var displayName: String {
        return self.rawValue
    }
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .detailed: return "txt"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .pdf: return "application/pdf"
        case .detailed: return "text/plain"
        }
    }
}

/// Export configuration options
struct ExportConfiguration {
    let format: ExportFormat
    let includeRawData: Bool
    let includeMetrics: Bool
    let includeFaults: Bool
    let includeRecommendations: Bool
    let includeTimestamps: Bool
    
    static let `default` = ExportConfiguration(
        format: .json,
        includeRawData: true,
        includeMetrics: true,
        includeFaults: true,
        includeRecommendations: true,
        includeTimestamps: true
    )
}

/// Main export container for swing analysis
struct SwingAnalysisExport: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let analysis: SwingAnalysisDataExport
    
    init(analysis: SwingAnalysis, appVersion: String = "1.0.0") {
        self.version = "1.0"
        self.exportDate = Date()
        self.appVersion = appVersion
        self.analysis = SwingAnalysisDataExport(analysis: analysis)
    }
}

/// Batch export for multiple analyses
struct BatchSwingAnalysisExport: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let totalAnalyses: Int
    let dateRange: DateRange
    let analyses: [SwingAnalysisDataExport]
    
    struct DateRange: Codable {
        let start: Date
        let end: Date
    }
    
    init(analyses: [SwingAnalysis], appVersion: String = "1.0.0") {
        self.version = "1.0"
        self.exportDate = Date()
        self.appVersion = appVersion
        self.totalAnalyses = analyses.count
        
        let dates = analyses.map { $0.timestamp }.sorted()
        self.dateRange = DateRange(
            start: dates.first ?? Date(),
            end: dates.last ?? Date()
        )
        
        self.analyses = analyses.map { SwingAnalysisDataExport(analysis: $0) }
    }
}

/// Video analysis export model
struct VideoAnalysisExport: Codable {
    let processedAt: Date
    let totalFrames: Int
    let analyzedFrames: Int
    let duration: Double
    let swingAnalysis: SwingAnalysisDataExport
    
    init(videoResult: VideoAnalysisResult) {
        self.processedAt = videoResult.processedAt
        self.totalFrames = videoResult.totalFrames
        self.analyzedFrames = videoResult.analyzedFrames
        self.duration = videoResult.duration
        self.swingAnalysis = SwingAnalysisDataExport(analysisData: videoResult.swingAnalysis)
    }
}

/// Detailed swing metrics for export
struct SwingMetricsExport: Codable {
    let tempo: Double
    let balance: Double
    let swingPathDeviation: Double
    let unit: String
    
    init(metrics: SwingMetrics) {
        self.tempo = metrics.tempo
        self.balance = metrics.balance
        self.swingPathDeviation = metrics.swingPathDeviation
        self.unit = "metric"
    }
}

/// Swing fault information for export
struct SwingFaultExport: Codable {
    let id: String
    let type: String
    let severity: String
    let description: String
    let recommendation: String
    
    init(fault: SwingFault) {
        self.id = fault.id.uuidString
        self.type = fault.type.rawValue
        self.severity = fault.severity.rawValue
        self.description = fault.description
        self.recommendation = fault.recommendation
    }
}

/// Swing phase information for export
struct SwingPhaseExport: Codable {
    let phase: String
    let startFrame: Int
    let endFrame: Int
    let duration: Double
    
    init(phaseData: SwingPhaseData) {
        self.phase = phaseData.phase.rawValue
        self.startFrame = phaseData.startFrame
        self.endFrame = phaseData.endFrame
        self.duration = phaseData.duration
    }
}

/// Complete swing analysis data for export
struct SwingAnalysisDataExport: Codable {
    let id: String
    let timestamp: Date
    let currentPhase: String
    let metrics: SwingMetricsExport
    let scores: SwingScoresExport
    let faults: [SwingFaultExport]
    let phases: [SwingPhaseExport]
    let recommendations: [SwingRecommendationExport]
    let keypointsCount: Int
    let averageConfidence: Double
    
    init(analysis: SwingAnalysis) {
        self.id = analysis.id.uuidString
        self.timestamp = analysis.timestamp
        self.currentPhase = analysis.phase.rawValue
        self.metrics = SwingMetricsExport(metrics: analysis.metrics)
        self.scores = SwingScoresExport(scores: analysis.scores)
        self.faults = analysis.faults.map { SwingFaultExport(fault: $0) }
        self.phases = analysis.swingPhases.values.map { SwingPhaseExport(phaseData: $0) }
        self.recommendations = analysis.recommendations.map { SwingRecommendationExport(recommendation: $0) }
        self.keypointsCount = analysis.keypoints.count
        self.averageConfidence = analysis.confidenceScores.isEmpty ? 0.0 : 
            Double(analysis.confidenceScores.reduce(0, +)) / Double(analysis.confidenceScores.count)
    }
    
    init(analysisData: SwingAnalysisData) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.currentPhase = "complete"
        self.metrics = SwingMetricsExport(metrics: analysisData.averageMetrics)
        self.scores = SwingScoresExport(scores: SwingScores(overall: 0.8, tempo: 0.8, balance: 0.8))
        self.faults = []
        self.phases = []
        self.recommendations = []
        self.keypointsCount = 0
        self.averageConfidence = 0.8
    }
}

/// Swing phase detailed information for export
struct SwingPhaseInfoExport: Codable {
    let phases: [String: SwingPhaseExport]
    let totalDuration: Double
    let phaseCount: Int
    
    init(from swingPhases: [SwingPhase: SwingPhaseData]) {
        var phasesDict: [String: SwingPhaseExport] = [:]
        var totalDur = 0.0
        
        for (phase, data) in swingPhases {
            phasesDict[phase.rawValue] = SwingPhaseExport(phaseData: data)
            totalDur += data.duration
        }
        
        self.phases = phasesDict
        self.totalDuration = totalDur
        self.phaseCount = swingPhases.count
    }
}

/// Swing scores for export
struct SwingScoresExport: Codable {
    let overall: Double
    let tempo: Double
    let balance: Double
    let grade: String
    
    init(scores: SwingScores) {
        self.overall = scores.overall
        self.tempo = scores.tempo
        self.balance = scores.balance
        self.grade = SwingScoresExport.calculateGrade(from: scores.overall)
    }
    
    private static func calculateGrade(from score: Double) -> String {
        switch score {
        case 0.9...: return "A+"
        case 0.85..<0.9: return "A"
        case 0.8..<0.85: return "A-"
        case 0.75..<0.8: return "B+"
        case 0.7..<0.75: return "B"
        case 0.65..<0.7: return "B-"
        case 0.6..<0.65: return "C+"
        case 0.55..<0.6: return "C"
        case 0.5..<0.55: return "C-"
        default: return "D"
        }
    }
}

/// Swing recommendation for export
struct SwingRecommendationExport: Codable {
    let id: String
    let title: String
    let description: String
    let priority: String
    
    init(recommendation: SwingRecommendation) {
        self.id = recommendation.id.uuidString
        self.title = recommendation.title
        self.description = recommendation.description
        self.priority = recommendation.priority.rawValue
    }
}

/// Export metadata and statistics
struct ExportMetadata: Codable {
    let exportId: String
    let exportDate: Date
    let appVersion: String
    let dataVersion: String
    let totalAnalyses: Int
    let averageScore: Double
    let topFaults: [String]
    let dateRange: DateRange
    
    struct DateRange: Codable {
        let start: Date
        let end: Date
        let days: Int
        
        init(start: Date, end: Date) {
            self.start = start
            self.end = end
            self.days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        }
    }
    
    init(analyses: [SwingAnalysis], appVersion: String = "1.0.0") {
        self.exportId = UUID().uuidString
        self.exportDate = Date()
        self.appVersion = appVersion
        self.dataVersion = "1.0"
        self.totalAnalyses = analyses.count
        
        // Calculate average score
        let scores = analyses.map { $0.scores.overall }
        self.averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        // Find top faults
        let allFaults = analyses.flatMap { $0.faults }
        let faultCounts = Dictionary(grouping: allFaults) { $0.type.rawValue }
        self.topFaults = faultCounts.sorted { $0.value.count > $1.value.count }
            .prefix(5)
            .map { $0.key }
        
        // Date range
        let dates = analyses.map { $0.timestamp }.sorted()
        self.dateRange = DateRange(
            start: dates.first ?? Date(),
            end: dates.last ?? Date()
        )
    }
}

/// CSV export row structure
struct CSVExportRow {
    let timestamp: String
    let phase: String
    let tempo: String
    let balance: String
    let swingPathDeviation: String
    let overallScore: String
    let faultCount: String
    let topFault: String
    
    init(from analysis: SwingAnalysis) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        self.timestamp = formatter.string(from: analysis.timestamp)
        self.phase = analysis.phase.description
        self.tempo = analysis.metrics.tempoFormatted
        self.balance = analysis.metrics.balanceFormatted
        self.swingPathDeviation = analysis.metrics.swingPathDeviationFormatted
        self.overallScore = String(format: "%.1f", analysis.scores.overall * 100)
        self.faultCount = String(analysis.faults.count)
        self.topFault = analysis.faults.first?.type.rawValue ?? "None"
    }
    
    static var csvHeader: String {
        return "Timestamp,Phase,Tempo,Balance,Swing Path Deviation,Overall Score,Fault Count,Top Fault"
    }
    
    var csvRow: String {
        return "\(timestamp),\(phase),\(tempo),\(balance),\(swingPathDeviation),\(overallScore),\(faultCount),\(topFault)"
    }
}
