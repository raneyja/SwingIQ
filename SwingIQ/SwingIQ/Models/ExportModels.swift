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

/// Export-compatible version of SwingAnalysis
struct ExportableSwingAnalysis: Codable {
    let id: String
    let timestamp: Date
    let phase: String
    let metrics: SwingMetrics
    let scores: SwingScores
    let faults: [SwingFault]
    let recommendations: [SwingRecommendation]
    
    init(from analysis: SwingAnalysis) {
        self.id = analysis.id.uuidString
        self.timestamp = analysis.timestamp
        self.phase = analysis.phase.rawValue
        self.metrics = analysis.metrics
        self.scores = analysis.scores
        self.faults = analysis.faults
        self.recommendations = analysis.recommendations
    }
}

/// Main export container for swing analysis
struct SwingAnalysisExport: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let analysis: ExportableSwingAnalysis
    
    init(analysis: SwingAnalysis, appVersion: String = "1.0.0") {
        self.version = "1.0"
        self.exportDate = Date()
        self.appVersion = appVersion
        self.analysis = ExportableSwingAnalysis(from: analysis)
    }
}

/// Batch export for multiple analyses
struct BatchSwingAnalysisExport: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let totalAnalyses: Int
    let dateRange: DateRange
    let analyses: [ExportableSwingAnalysis]
    
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
        
        self.analyses = analyses.map { ExportableSwingAnalysis(from: $0) }
    }
}

/// Video analysis export model - now just uses core VideoAnalysisResult
struct VideoAnalysisExport: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let videoResult: VideoAnalysisResult
    
    init(videoResult: VideoAnalysisResult, appVersion: String = "1.0.0") {
        self.version = "1.0"
        self.exportDate = Date()
        self.appVersion = appVersion
        self.videoResult = videoResult
    }
}

/// All video analysis models are now directly Codable in SwingModels.swift
/// No wrapper types needed anymore

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
