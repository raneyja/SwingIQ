//
//  LiveMetricsPanel.swift
//  SwingIQ
//
//  Live metrics panel with AI feedback for analysis results
//

import SwiftUI

struct LiveMetricsPanel: View {
    let analysisResults: SwingAnalysisResults?
    let enhancedAnalysis: SwingAnalysis?
    
    private var liveTempo: Double {
        analysisResults?.tempo ?? 3.0
    }
    
    private var liveSwingPathDeviation: Double {
        analysisResults?.swingPathDeviation ?? 0.0
    }
    
    private var liveSwingPathDescription: String {
        let deviation = liveSwingPathDeviation
        if abs(deviation) < 2.0 {
            return "On Plane"
        } else if deviation < 0 {
            return "Inside-Out"
        } else {
            return "Outside-In"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Live swing metrics
            swingMetricsSection
            
            // AI feedback section
            if let enhancedAnalysis = enhancedAnalysis {
                aiFeedbackSection(enhancedAnalysis)
            }
        }
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.95))
    }
    
    // MARK: - Swing Metrics Section
    
    private var swingMetricsSection: some View {
        HStack(spacing: 8) {
            LiveSwingAnalysisMetricCard(
                title: "Tempo",
                value: String(format: "%.1f:1", liveTempo),
                unit: "",
                color: tempoColor(liveTempo),
                icon: "metronome"
            )
            
            LiveSwingAnalysisMetricCard(
                title: "Swing Path",
                value: liveSwingPathDescription,
                unit: "",
                color: swingPathColor(liveSwingPathDeviation),
                icon: "arrow.triangle.swap"
            )
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - AI Feedback Section
    
    private func aiFeedbackSection(_ analysis: SwingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                Text("AI Feedback")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Gemini")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let feedback = analysis.recommendations.first?.description {
                Text(feedback)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Quick improvements summary
            if !analysis.recommendations.isEmpty {
                improvementsSummary(analysis.recommendations.map { $0.description })
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func improvementsSummary(_ improvements: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Key Focus Areas:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(Array(improvements.prefix(2).enumerated()), id: \.offset) { index, improvement in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text(improvement)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Color Helpers
    
    private func tempoColor(_ tempo: Double) -> Color {
        let ideal = 3.0
        let difference = abs(tempo - ideal)
        switch difference {
        case 0..<0.5: return .green
        case 0.5..<1.0: return .yellow
        default: return .orange
        }
    }
    
    private func swingPathColor(_ deviation: Double) -> Color {
        switch abs(deviation) {
        case 0..<2.0: return .green
        case 2.0..<5.0: return .yellow
        default: return .orange
        }
    }
}

struct LiveSwingAnalysisMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
