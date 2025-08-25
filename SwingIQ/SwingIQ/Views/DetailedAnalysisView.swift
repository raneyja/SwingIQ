//
//  DetailedAnalysisView.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//

import SwiftUI
import Charts

struct DetailedAnalysisView: View {
    let analysis: SwingAnalysis
    @State private var selectedTab: DetailTab = .overview
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case metrics = "Metrics"
        case faults = "Faults"
        case recommendations = "Tips"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with overall score
                headerSection
                
                // Tab selector
                tabSelector
                
                // Tab content
                tabContent
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analysis Details")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Overall score circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: analysis.scores.overall)
                    .stroke(scoreColor(analysis.scores.overall * 100), lineWidth: 12)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: analysis.scores.overall)
                
                VStack(spacing: 4) {
                    Text("\(Int(analysis.scores.overall * 100))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(analysis.scores.overall * 100))
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timestamp
            Text(analysis.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Quick metrics
            HStack(spacing: 20) {
                quickMetric(title: "Balance", value: analysis.scores.balance, color: .blue)
                quickMetric(title: "Tempo", value: analysis.scores.tempo, color: .green)
                quickMetric(title: "Tempo", value: analysis.scores.tempo, color: .purple)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func quickMetric(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value * 100))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewTab
        case .metrics:
            metricsTab
        case .faults:
            faultsTab
        case .recommendations:
            recommendationsTab
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(spacing: 20) {
            // Swing phase breakdown
            swingPhaseCard
            
            // Key highlights
            highlightsCard
        }
    }
    
    private var swingPhaseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swing Phases")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Simplified phase timeline
            if let swingPhases = analysis.swingPhases as? [SwingPhase: SwingPhaseData] {
                VStack(spacing: 8) {
                    ForEach(SwingPhase.allCases.filter { $0 != .unknown }, id: \.self) { phase in
                        if let phaseData = swingPhases[phase] {
                            phaseRow(phase: phase, data: phaseData)
                        }
                    }
                }
            } else {
                Text("Phase data not available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func phaseRow(phase: SwingPhase, data: SwingPhaseData) -> some View {
        HStack {
            Circle()
                .fill(phaseColor(for: phase))
                .frame(width: 8, height: 8)
            
            Text(phase.rawValue.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(String(format: "%.1fs", data.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Highlights")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                highlightRow(
                    icon: "star.fill",
                    title: "Best Area",
                    description: getBestArea(),
                    color: .green
                )
                
                highlightRow(
                    icon: "exclamationmark.triangle",
                    title: "Focus Area", 
                    description: getFocusArea(),
                    color: .orange
                )
                
                highlightRow(
                    icon: "target",
                    title: "Improvement",
                    description: getImprovementSuggestion(),
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func highlightRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Metrics Tab
    
    private var metricsTab: some View {
        VStack(spacing: 16) {
            metricsDetailCard(
                title: "Balance Score",
                value: analysis.scores.balance,
                description: "Your stability throughout the swing",
                icon: "figure.gymnastics"
            )
            
            metricsDetailCard(
                title: "Tempo Score", 
                value: analysis.scores.tempo,
                description: "Rhythm and timing of your swing",
                icon: "metronome"
            )
            
            metricsDetailCard(
                title: "Balance Score",
                value: analysis.scores.balance, 
                description: "Stability throughout the swing",
                icon: "figure.gymnastics"
            )
        }
    }
    
    private func metricsDetailCard(title: String, value: Double, description: String, icon: String) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(value * 100))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(value * 100))
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(scoreColor(value * 100))
                    .frame(width: value * UIScreen.main.bounds.width * 0.8, height: 8)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Faults Tab
    
    private var faultsTab: some View {
        VStack(spacing: 16) {
            if analysis.faults.isEmpty {
                noFaultsView
            } else {
                ForEach(analysis.faults, id: \.id) { fault in
                    faultDetailCard(fault: fault)
                }
            }
        }
    }
    
    private var noFaultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 60))
            
            Text("Excellent Swing!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("No major swing faults detected in this analysis. Keep up the great work!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func faultDetailCard(fault: SwingFault) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: faultIcon(for: fault.type))
                    .foregroundColor(faultColor(for: fault.severity))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fault.type.rawValue.capitalized)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Severity: \(fault.severity.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(faultColor(for: fault.severity))
                }
                
                Spacer()
            }
            
            Text(fault.description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text("💡 \(fault.recommendation)")
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Recommendations Tab
    
    private var recommendationsTab: some View {
        VStack(spacing: 16) {
            if analysis.recommendations.isEmpty {
                noRecommendationsView
            } else {
                ForEach(analysis.recommendations, id: \.id) { recommendation in
                    recommendationDetailCard(recommendation: recommendation)
                }
            }
        }
    }
    
    private var noRecommendationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 60))
            
            Text("No Specific Tips")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Your swing analysis didn't identify any specific areas for improvement. Keep practicing!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func recommendationDetailCard(recommendation: SwingRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(priorityColor(recommendation.priority))
                    .frame(width: 12, height: 12)
                
                Text(recommendation.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(recommendation.priority.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(recommendation.priority).opacity(0.2))
                    .foregroundColor(priorityColor(recommendation.priority))
                    .cornerRadius(8)
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            HStack {
                Button(action: {
                    // Mark as completed
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Practiced")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to recording
                }) {
                    HStack {
                        Image(systemName: "video.circle")
                        Text("Practice Now")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func phaseColor(for phase: SwingPhase) -> Color {
        switch phase {
        case .address: return .gray
        case .takeaway: return .blue
        case .backswing: return .purple
        case .transition: return .orange
        case .downswing: return .red
        case .impact: return .green
        case .followThrough: return .yellow
        case .finish: return .pink
        case .unknown: return .gray
        }
    }
    
    private func faultIcon(for type: SwingFault.FaultType) -> String {
        switch type {
        case .posture:
            return "figure.stand.line.dotted.figure.stand"
        case .swingPlane:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .tempo:
            return "metronome"
        case .balance:
            return "figure.gymnastics"
        }
    }
    
    private func faultColor(for severity: SwingFault.FaultSeverity) -> Color {
        switch severity {
        case .low:
            return .yellow
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
    
    private func priorityColor(_ priority: SwingRecommendation.RecommendationPriority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private func getBestArea() -> String {
        let scores = [
            ("Balance", analysis.scores.balance),
            ("Tempo", analysis.scores.tempo)
        ]
        
        let best = scores.max { $0.1 < $1.1 }
        return best?.0 ?? "Overall performance"
    }
    
    private func getFocusArea() -> String {
        let scores = [
            ("Balance", analysis.scores.balance),
            ("Tempo", analysis.scores.tempo)
        ]
        
        let worst = scores.min { $0.1 < $1.1 }
        return worst?.0 ?? "Continue current practice"
    }
    
    private func getImprovementSuggestion() -> String {
        if analysis.scores.overall >= 0.8 {
            return "Maintain your excellent form"
        } else if analysis.scores.overall >= 0.6 {
            return "Focus on consistency and timing"
        } else {
            return "Work on fundamental mechanics"
        }
    }
}



#Preview {
    NavigationView {
        DetailedAnalysisView(analysis: SwingAnalysis(
            id: UUID(),
            timestamp: Date(),
            phase: .impact,
            metrics: SwingMetrics(
                tempo: 3.0,
                balance: 0.85,
                swingPathDeviation: 2.0
            ),
            keypoints: [],
            confidenceScores: [],
            swingPhases: [:],
            faults: [],
            scores: SwingScores(
                overall: 0.82,
                tempo: 0.78,
                balance: 0.85
            ),
            recommendations: []
        ))
    }
}
