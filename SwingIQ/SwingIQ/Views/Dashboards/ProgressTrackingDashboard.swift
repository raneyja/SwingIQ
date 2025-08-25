//
//  ProgressTrackingDashboard.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//

import SwiftUI
import Charts

struct ProgressTrackingDashboard: View {
    let analyses: [SwingAnalysis]
    @State private var selectedTimeRange: TimeRange = .thirtyDays
    @State private var selectedMetric: MetricType = .overallScore
    
    enum TimeRange: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"
        case allTime = "All"
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            case .allTime: return 365 * 10 // Large number for all time
            }
        }
    }
    
    enum MetricType: String, CaseIterable {
        case overallScore = "Overall Score"
        case balance = "Balance"
        case consistency = "Consistency"
        case tempo = "Tempo"
        
        var icon: String {
            switch self {
            case .overallScore: return "chart.bar.fill"
            case .balance: return "figure.gymnastics"
            case .consistency: return "arrow.clockwise"
            case .tempo: return "metronome"
            }
        }
    }
    
    private var filteredAnalyses: [SwingAnalysis] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return analyses.filter { $0.timestamp >= cutoffDate }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var improvementPercentage: Double {
        guard filteredAnalyses.count >= 2 else { return 0 }
        
        let recentValues = getMetricValues(for: selectedMetric, from: Array(filteredAnalyses.suffix(3)))
        let earlierValues = getMetricValues(for: selectedMetric, from: Array(filteredAnalyses.prefix(3)))
        
        guard !recentValues.isEmpty && !earlierValues.isEmpty else { return 0 }
        
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let earlierAvg = earlierValues.reduce(0, +) / Double(earlierValues.count)
        
        guard earlierAvg > 0 else { return 0 }
        return ((recentAvg - earlierAvg) / earlierAvg) * 100
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with controls
                headerSection
                
                // Progress Overview Cards
                progressOverviewCards
                
                // Main Progress Chart
                progressChart
                
                // AI Recommendations Tracking
                aiRecommendationsSection
                
                // Goal Setting Section
                goalSettingSection
                
                // Milestone Achievements
                milestonesSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress Tracking")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Metric selector
            Picker("Metric", selection: $selectedMetric) {
                ForEach(MetricType.allCases, id: \.self) { metric in
                    HStack {
                        Image(systemName: metric.icon)
                        Text(metric.rawValue)
                    }.tag(metric)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    // MARK: - Progress Overview Cards
    
    private var progressOverviewCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                progressCard(
                    title: "Improvement",
                    value: String(format: "%.1f%%", improvementPercentage),
                    subtitle: "this period",
                    color: improvementPercentage >= 0 ? .green : .red,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                progressCard(
                    title: "Sessions",
                    value: "\(filteredAnalyses.count)",
                    subtitle: "completed",
                    color: .blue,
                    icon: "figure.golf"
                )
                
                progressCard(
                    title: "Current",
                    value: String(format: "%.0f", getCurrentScore()),
                    subtitle: "score",
                    color: scoreColor(getCurrentScore()),
                    icon: "target"
                )
            }
        }
    }
    
    private func progressCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Progress Chart
    
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedMetric.rawValue) Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(filteredAnalyses.enumerated()), id: \.1.id) { index, analysis in
                        LineMark(
                            x: .value("Session", index),
                            y: .value("Score", getMetricValue(for: selectedMetric, from: analysis))
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle())
                        
                        AreaMark(
                            x: .value("Session", index),
                            y: .value("Score", getMetricValue(for: selectedMetric, from: analysis))
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                    
                    // Trend line
                    if filteredAnalyses.count >= 2 {
                        LineMark(
                            x: .value("Start", 0),
                            y: .value("Start Trend", getTrendValue(at: 0))
                        )
                        .foregroundStyle(.green.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        
                        LineMark(
                            x: .value("End", filteredAnalyses.count - 1),
                            y: .value("End Trend", getTrendValue(at: filteredAnalyses.count - 1))
                        )
                        .foregroundStyle(.green.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
                .chartYScale(domain: [0, 100])
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("Progress chart requires iOS 16+")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - AI Recommendations Section
    
    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendations Tracking")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let latestAnalysis = filteredAnalyses.last, !latestAnalysis.recommendations.isEmpty {
                VStack(spacing: 8) {
                    ForEach(latestAnalysis.recommendations.prefix(3), id: \.id) { recommendation in
                        recommendationRow(recommendation: recommendation)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("No recommendations available")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func recommendationRow(recommendation: SwingRecommendation) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priorityColor(recommendation.priority))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {
                // Mark as worked on
            }) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Goal Setting Section
    
    private var goalSettingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Setting")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                goalCard(
                    title: "Target Score",
                    current: getCurrentScore(),
                    target: 85,
                    unit: "points"
                )
                
                goalCard(
                    title: "Sessions Goal",
                    current: Double(filteredAnalyses.count),
                    target: 20,
                    unit: "sessions"
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func goalCard(title: String, current: Double, target: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(current))/\(Int(target)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(.blue)
                    .frame(width: (current / target) * 200, height: 8)
                    .cornerRadius(4)
            }
            .frame(width: 200)
            
            Text("\(Int((current / target) * 100))% Complete")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Milestones Section
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                milestoneCard(
                    title: "First Analysis",
                    description: "Complete your first swing analysis",
                    isCompleted: !analyses.isEmpty,
                    icon: "star.fill"
                )
                
                milestoneCard(
                    title: "Score 80+",
                    description: "Achieve a score of 80 or higher",
                    isCompleted: analyses.contains { $0.scores.overall >= 0.8 },
                    icon: "trophy.fill"
                )
                
                milestoneCard(
                    title: "10 Sessions",
                    description: "Complete 10 practice sessions",
                    isCompleted: analyses.count >= 10,
                    icon: "flame.fill"
                )
                
                milestoneCard(
                    title: "Consistent Week",
                    description: "Practice 5 days in one week",
                    isCompleted: false, // Would need to check dates
                    icon: "calendar"
                )
            }
        }
    }
    
    private func milestoneCard(title: String, description: String, isCompleted: Bool, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isCompleted ? .yellow : .gray)
                .font(.title2)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isCompleted ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? Color.yellow : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentScore() -> Double {
        guard let latest = filteredAnalyses.last else { return 0 }
        return getMetricValue(for: selectedMetric, from: latest)
    }
    
    private func getMetricValue(for metric: MetricType, from analysis: SwingAnalysis) -> Double {
        switch metric {
        case .overallScore:
            return analysis.scores.overall * 100
        case .balance:
            return analysis.scores.balance * 100
        case .consistency:
            return analysis.scores.balance * 100 // Using balance as substitute
        case .tempo:
            return analysis.scores.tempo * 100
        }
    }
    
    private func getMetricValues(for metric: MetricType, from analyses: [SwingAnalysis]) -> [Double] {
        return analyses.map { getMetricValue(for: metric, from: $0) }
    }
    
    private func getTrendValue(at index: Int) -> Double {
        guard filteredAnalyses.count >= 2 else { return 0 }
        
        let values = getMetricValues(for: selectedMetric, from: filteredAnalyses)
        let firstValue = values.first ?? 0
        let lastValue = values.last ?? 0
        let totalSteps = Double(filteredAnalyses.count - 1)
        
        guard totalSteps > 0 else { return firstValue }
        
        let stepSize = (lastValue - firstValue) / totalSteps
        return firstValue + (stepSize * Double(index))
    }
    
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
}

#Preview {
    NavigationView {
        ProgressTrackingDashboard(analyses: [])
    }
}
