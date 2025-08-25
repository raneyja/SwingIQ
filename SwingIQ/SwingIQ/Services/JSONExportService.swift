//
//  JSONExportService.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import UIKit

@MainActor
class JSONExportService: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportURL: URL?
    @Published var exportError: String?
    
    // MARK: - Public Export Methods
    
    func exportSwingAnalysis(_ analysis: SwingAnalysis, format: ExportFormat = .json) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        exportError = nil
        
        defer {
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportProgress = 1.0
            }
        }
        
        do {
            let exportData = try await generateExportData(for: analysis, format: format)
            let url = try await saveExportData(exportData, format: format, analysis: analysis)
            
            DispatchQueue.main.async {
                self.lastExportURL = url
            }
            
            return url
        } catch {
            DispatchQueue.main.async {
                self.exportError = error.localizedDescription
            }
            throw error
        }
    }
    
    func exportMultipleAnalyses(_ analyses: [SwingAnalysis], format: ExportFormat = .json) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        exportError = nil
        
        defer {
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportProgress = 1.0
            }
        }
        
        do {
            let exportData = try await generateBatchExportData(for: analyses, format: format)
            let url = try await saveBatchExportData(exportData, format: format, count: analyses.count)
            
            DispatchQueue.main.async {
                self.lastExportURL = url
            }
            
            return url
        } catch {
            DispatchQueue.main.async {
                self.exportError = error.localizedDescription
            }
            throw error
        }
    }
    
    func exportVideoAnalysis(_ videoResult: VideoAnalysisResult, format: ExportFormat = .json) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        exportError = nil
        
        defer {
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportProgress = 1.0
            }
        }
        
        do {
            let exportData = try await generateVideoExportData(for: videoResult, format: format)
            let url = try await saveVideoExportData(exportData, format: format, videoResult: videoResult)
            
            DispatchQueue.main.async {
                self.lastExportURL = url
            }
            
            return url
        } catch {
            DispatchQueue.main.async {
                self.exportError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Data Generation
    
    private func generateExportData(for analysis: SwingAnalysis, format: ExportFormat) async throws -> Data {
        updateProgress(0.2)
        
        switch format {
        case .json:
            return try generateJSONData(for: analysis)
        case .csv:
            return try generateCSVData(for: analysis)
        case .detailed:
            return try generateDetailedData(for: analysis)
        case .pdf:
            return try generateDetailedData(for: analysis) // Use text for now
        }
    }
    
    private func generateBatchExportData(for analyses: [SwingAnalysis], format: ExportFormat) async throws -> Data {
        updateProgress(0.1)
        
        switch format {
        case .json:
            return try generateBatchJSONData(for: analyses)
        case .csv:
            return try generateBatchCSVData(for: analyses)
        case .detailed:
            return try generateBatchDetailedData(for: analyses)
        case .pdf:
            return try generateBatchDetailedData(for: analyses) // Use text for now
        }
    }
    
    private func generateVideoExportData(for videoResult: VideoAnalysisResult, format: ExportFormat) async throws -> Data {
        updateProgress(0.2)
        
        switch format {
        case .json:
            return try generateVideoJSONData(for: videoResult)
        case .csv:
            return try generateVideoCSVData(for: videoResult)
        case .detailed:
            return try generateVideoDetailedData(for: videoResult)
        case .pdf:
            return try generateVideoDetailedData(for: videoResult) // Use text for now
        }
    }
    
    // MARK: - JSON Export
    
    private func generateJSONData(for analysis: SwingAnalysis) throws -> Data {
        let exportModel = SwingAnalysisExport(analysis: analysis)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        updateProgress(0.6)
        return try encoder.encode(exportModel)
    }
    
    private func generateBatchJSONData(for analyses: [SwingAnalysis]) throws -> Data {
        let exportModel = BatchSwingAnalysisExport(analyses: analyses)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        updateProgress(0.7)
        return try encoder.encode(exportModel)
    }
    
    private func generateVideoJSONData(for videoResult: VideoAnalysisResult) throws -> Data {
        let exportModel = VideoAnalysisExport(videoResult: videoResult)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        updateProgress(0.6)
        return try encoder.encode(exportModel)
    }
    
    // MARK: - CSV Export
    
    private func generateCSVData(for analysis: SwingAnalysis) throws -> Data {
        var csvContent = "Timestamp,Metric,Value,Phase,Score\n"
        
        // Add basic metrics
        csvContent += "\(analysis.timestamp.timeIntervalSince1970),Tempo,\(analysis.metrics.tempo),Overall,\(analysis.scores.tempo)\n"
        csvContent += "\(analysis.timestamp.timeIntervalSince1970),Balance,\(analysis.metrics.balance),Overall,\(analysis.scores.balance)\n"
        csvContent += "\(analysis.timestamp.timeIntervalSince1970),SwingPathDeviation,\(analysis.metrics.swingPathDeviation),Overall,\(analysis.scores.overall)\n"
        
        // Add phase data
        for (phaseType, phaseData) in analysis.swingPhases {
            csvContent += "\(analysis.timestamp.timeIntervalSince1970),PhaseDuration,\(phaseData.duration),\(phaseType.rawValue),\(analysis.scores.overall)\n"
        }
        
        updateProgress(0.8)
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generateBatchCSVData(for analyses: [SwingAnalysis]) throws -> Data {
        var csvContent = "AnalysisID,Timestamp,Metric,Value,Phase,Score\n"
        
        for analysis in analyses {
            let baseData = "\(analysis.id.uuidString),\(analysis.timestamp.timeIntervalSince1970)"
            
            csvContent += "\(baseData),SwingPath,\(analysis.metrics.swingPathDeviation),Overall,\(analysis.scores.overall)\n"
            csvContent += "\(baseData),Tempo,\(analysis.metrics.tempo),Overall,\(analysis.scores.tempo)\n"
            csvContent += "\(baseData),Balance,\(analysis.metrics.balance),Overall,\(analysis.scores.balance)\n"
        }
        
        updateProgress(0.8)
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generateVideoCSVData(for videoResult: VideoAnalysisResult) throws -> Data {
        var csvContent = "FrameIndex,Timestamp,Metric,Value,Confidence,Phase\n"
        
        // This would iterate through processed frames if available
        // For now, we'll export summary data
        
        let swingAnalysis = videoResult.swingAnalysis
        csvContent += "0,0.0,SwingPath,\(swingAnalysis.averageMetrics.swingPathDeviation),1.0,Summary\n"
        csvContent += "0,0.0,Tempo,\(swingAnalysis.averageMetrics.tempo),1.0,Summary\n"
        csvContent += "0,0.0,Balance,\(swingAnalysis.averageMetrics.balance),1.0,Summary\n"
        
        updateProgress(0.8)
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Detailed Export
    
    private func generateDetailedData(for analysis: SwingAnalysis) throws -> Data {
        let report = generateDetailedReport(for: analysis)
        updateProgress(0.8)
        return report.data(using: .utf8) ?? Data()
    }
    
    private func generateBatchDetailedData(for analyses: [SwingAnalysis]) throws -> Data {
        var report = "SwingIQ Batch Analysis Report\n"
        report += "Generated: \(Date().formatted())\n"
        report += "Total Analyses: \(analyses.count)\n\n"
        
        // Summary statistics
        let avgScore = analyses.map { $0.scores.overall }.reduce(0, +) / Double(analyses.count)
        let avgTempo = analyses.map { $0.metrics.tempo }.reduce(0, +) / Double(analyses.count)
        
        report += "Summary Statistics:\n"
        report += "Average Overall Score: \(String(format: "%.1f", avgScore))\n"
        report += "Average Tempo: \(String(format: "%.1f", avgTempo))\n\n"
        
        // Individual analyses
        for (index, analysis) in analyses.enumerated() {
            report += "Analysis \(index + 1):\n"
            report += generateDetailedReport(for: analysis)
            report += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }
        
        updateProgress(0.8)
        return report.data(using: .utf8) ?? Data()
    }
    
    private func generateVideoDetailedData(for videoResult: VideoAnalysisResult) throws -> Data {
        var report = "SwingIQ Video Analysis Report\n"
        report += "Generated: \(Date().formatted())\n"
        report += "Video Duration: \(String(format: "%.2f seconds", videoResult.duration))\n"
        report += "Total Frames: \(videoResult.totalFrames)\n"
        report += "Analyzed Frames: \(videoResult.analyzedFrames)\n\n"
        
        let analysis = videoResult.swingAnalysis
        
        report += "Swing Metrics:\n"
        report += "Swing Path Deviation: \(analysis.averageMetrics.swingPathDeviationFormatted)\n"
        report += "Tempo Ratio: \(analysis.averageMetrics.tempoFormatted)\n"
        report += "Balance Score: \(analysis.averageMetrics.balanceFormatted)\n\n"
        
        // Swing phases
        report += "Swing Phases:\n"
        for phase in analysis.phases {
            report += "\(phase.phase.description): \(String(format: "%.3f seconds", phase.duration))\n"
        }
        report += "\n"
        
        // Frame analytics
        let frameAnalytics = videoResult.frameAnalytics
        report += "Frame Analysis:\n"
        report += "High Confidence Frames: \(frameAnalytics.highConfidenceFrames) (\(String(format: "%.1f%%", Double(frameAnalytics.highConfidenceFrames) / Double(frameAnalytics.totalFrames) * 100)))\n"
        report += "Medium Confidence Frames: \(frameAnalytics.mediumConfidenceFrames) (\(String(format: "%.1f%%", Double(frameAnalytics.mediumConfidenceFrames) / Double(frameAnalytics.totalFrames) * 100)))\n"
        report += "Low Confidence Frames: \(frameAnalytics.lowConfidenceFrames) (\(String(format: "%.1f%%", Double(frameAnalytics.lowConfidenceFrames) / Double(frameAnalytics.totalFrames) * 100)))\n"
        report += "Average Confidence: \(String(format: "%.2f", frameAnalytics.averageConfidence))\n\n"
        
        // Recommendations
        if !videoResult.recommendations.isEmpty {
            report += "Recommendations:\n"
            for (index, recommendation) in videoResult.recommendations.enumerated() {
                report += "\(index + 1). \(recommendation.title) (Priority: \(recommendation.priority))\n"
                report += "   \(recommendation.description)\n"
                if !recommendation.frameReferences.isEmpty {
                    report += "   See frames: \(recommendation.frameReferences.map(String.init).joined(separator: ", "))\n"
                }
                report += "\n"
            }
        }
        
        updateProgress(0.8)
        return report.data(using: .utf8) ?? Data()
    }
    
    private func generateDetailedReport(for analysis: SwingAnalysis) -> String {
        var report = ""
        
        report += "Swing Analysis Report\n"
        report += "Timestamp: \(analysis.timestamp.formatted())\n"
        report += "Overall Score: \(String(format: "%.1f", analysis.scores.overall))\n\n"
        
        report += "Metrics:\n"
        report += "Swing Path Deviation: \(analysis.metrics.swingPathDeviationFormatted)\n"
        report += "Tempo: \(analysis.metrics.tempoFormatted)\n"
        report += "Balance: \(analysis.metrics.balanceFormatted)\n\n"
        
        report += "Scores:\n"
        report += "Overall: \(String(format: "%.1f", analysis.scores.overall))\n"
        report += "Tempo: \(String(format: "%.1f", analysis.scores.tempo))\n"
        report += "Balance: \(String(format: "%.1f", analysis.scores.balance))\n"
        report += "\n"
        
        if !analysis.faults.isEmpty {
            report += "Detected Faults:\n"
            for fault in analysis.faults {
                report += "- \(fault.description) (Severity: \(fault.severity.rawValue.capitalized))\n"
                report += "  Recommendation: \(fault.recommendation)\n"
            }
            report += "\n"
        }
        
        report += "Swing Phases:\n"
        for (phaseType, phaseData) in analysis.swingPhases {
            report += "\(phaseType.rawValue): \(String(format: "%.3f seconds", phaseData.duration))\n"
        }
        
        return report
    }
    
    // MARK: - File Operations
    
    private func saveExportData(_ data: Data, format: ExportFormat, analysis: SwingAnalysis) async throws -> URL {
        let fileName = "SwingAnalysis_\(analysis.timestamp.timeIntervalSince1970).\(format.fileExtension)"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        try data.write(to: url)
        updateProgress(1.0)
        
        return url
    }
    
    private func saveBatchExportData(_ data: Data, format: ExportFormat, count: Int) async throws -> URL {
        let fileName = "SwingAnalyses_\(count)_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        try data.write(to: url)
        updateProgress(1.0)
        
        return url
    }
    
    private func saveVideoExportData(_ data: Data, format: ExportFormat, videoResult: VideoAnalysisResult) async throws -> URL {
        let fileName = "VideoAnalysis_\(videoResult.processedAt.timeIntervalSince1970).\(format.fileExtension)"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        try data.write(to: url)
        updateProgress(1.0)
        
        return url
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.exportProgress = progress
        }
    }
}



struct FrameAnalyticsExport: Codable {
    let totalFrames: Int
    let highConfidenceFrames: Int
    let mediumConfidenceFrames: Int
    let lowConfidenceFrames: Int
    let averageConfidence: Double
    let minConfidence: Double
    let maxConfidence: Double
    
    init(analytics: FrameAnalytics) {
        self.totalFrames = analytics.totalFrames
        self.highConfidenceFrames = analytics.highConfidenceFrames
        self.mediumConfidenceFrames = analytics.mediumConfidenceFrames
        self.lowConfidenceFrames = analytics.lowConfidenceFrames
        self.averageConfidence = analytics.averageConfidence
        self.minConfidence = analytics.confidenceRange.min
        self.maxConfidence = analytics.confidenceRange.max
    }
}

struct VideoRecommendationExport: Codable {
    let type: String
    let priority: String
    let title: String
    let description: String
    let frameReferences: [Int]
    
    init(recommendation: VideoRecommendation) {
        self.type = String(describing: recommendation.type)
        self.priority = String(describing: recommendation.priority)
        self.title = recommendation.title
        self.description = recommendation.description
        self.frameReferences = recommendation.frameReferences
    }
}



