//
//  TempoDashboard.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import Charts

struct TempoDashboard: View {
    let analyses: [SwingAnalysis]
    @State private var selectedTimeRange: TimeRange = .thirtyDays
    
    enum TimeRange: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            }
        }
    }
    
    private var filteredAnalyses: [SwingAnalysis] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return analyses.filter { $0.timestamp >= cutoffDate }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var averageTempo: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let tempos = filteredAnalyses.map { $0.metrics.tempo }
        return tempos.reduce(0, +) / Double(tempos.count)
    }
    
    private var idealTempo: Double { 3.0 } // Professional ideal tempo ratio
    
    private var tempoDeviation: Double {
        abs(averageTempo - idealTempo)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with time range selector
                headerSection
                
                // Tempo metrics cards
                metricsCards
                
                // Tempo trend chart
                tempoTrendChart
                
                // Tempo consistency analysis
                tempoConsistency
                
                // Performance insights
                performanceInsights
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tempo")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tempo Analysis")
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
        }
    }
    
    // MARK: - Metrics Cards
    
    private var metricsCards: some View {
        HStack(spacing: 12) {
            metricCard(
                title: "Average", 
                value: String(format: "%.1f:1", averageTempo), 
                color: .blue
            )
            metricCard(
                title: "Ideal", 
                value: String(format: "%.1f:1", idealTempo), 
                color: .green
            )
            metricCard(
                title: "Deviation", 
                value: String(format: "±%.1f", tempoDeviation), 
                color: tempoDeviation < 0.3 ? .green : .orange
            )
        }
    }
    
    private func metricCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Tempo Trend Chart
    
    private var tempoTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tempo Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    // Ideal tempo line
                    RuleMark(y: .value("Ideal", idealTempo))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Actual tempo
                    ForEach(Array(filteredAnalyses.enumerated()), id: \.1.id) { index, analysis in
                        LineMark(
                            x: .value("Session", index),
                            y: .value("Tempo", analysis.metrics.tempo)
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle())
                    }
                }
                .chartYScale(domain: [0.8, 4.0])
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("Tempo trend chart requires iOS 16+")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Tempo Consistency
    
    private var tempoConsistency: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Consistency score
                consistencyScore
                
                // Tempo ranges
                tempoRanges
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private var consistencyScore: some View {
        let score = calculateConsistencyScore()
        
        return VStack(spacing: 8) {
            Text("Consistency Score")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(getConsistencyColor(score), lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: score)
                    
                    Text("\(Int(score))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getConsistencyColor(score))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(getConsistencyDescription(score))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Based on tempo variation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var tempoRanges: some View {
        let ranges = createTempoRanges()
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Tempo Distribution")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(ranges, id: \.range) { data in
                HStack {
                    Text(data.range)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                        
                        Rectangle()
                            .fill(.blue)
                            .frame(width: CGFloat(data.percentage) * 150, height: 16)
                    }
                    .cornerRadius(4)
                    
                    Text("\(data.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
    
    // MARK: - Performance Insights
    
    private var performanceInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "metronome",
                    title: "Tempo Quality",
                    description: getTempoQualityInsight(),
                    color: .blue
                )
                
                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Improvement",
                    description: getImprovementInsight(),
                    color: .green
                )
                
                insightCard(
                    icon: "lightbulb",
                    title: "Recommendation",
                    description: getRecommendation(),
                    color: .orange
                )
            }
        }
    }
    
    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func calculateConsistencyScore() -> Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        
        let tempos = filteredAnalyses.map { $0.metrics.tempo }
        let mean = tempos.reduce(0, +) / Double(tempos.count)
        let variance = tempos.map { pow($0 - mean, 2) }.reduce(0, +) / Double(tempos.count)
        let standardDeviation = sqrt(variance)
        
        // Convert to score (lower deviation = higher score)
        let coefficientOfVariation = (standardDeviation / mean) * 100
        return max(0, 100 - (coefficientOfVariation * 10))
    }
    
    private func getConsistencyColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private func getConsistencyDescription(_ score: Double) -> String {
        switch score {
        case 80...: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Work"
        }
    }
    
    private func createTempoRanges() -> [(range: String, count: Int, percentage: Double)] {
        let tempos = filteredAnalyses.map { $0.metrics.tempo }
        let total = tempos.count
        guard total > 0 else { return [] }
        
        let ranges = [
            ("1.0-1.5", tempos.filter { $0 >= 1.0 && $0 < 1.5 }.count),
            ("1.5-2.0", tempos.filter { $0 >= 1.5 && $0 < 2.0 }.count),
            ("2.0-2.5", tempos.filter { $0 >= 2.0 && $0 < 2.5 }.count),
            ("2.5-3.0", tempos.filter { $0 >= 2.5 && $0 < 3.0 }.count),
            ("3.0+", tempos.filter { $0 >= 3.0 }.count)
        ]
        
        return ranges.map { (range: $0.0, count: $0.1, percentage: Double($0.1) / Double(total)) }
    }
    
    private func getTempoQualityInsight() -> String {
        if tempoDeviation < 0.2 {
            return "Your tempo is very close to the professional ideal"
        } else if tempoDeviation < 0.5 {
            return "Your tempo is within good range of the ideal"
        } else {
            return "Focus on achieving a 3:1 backswing to downswing ratio"
        }
    }
    
    private func getImprovementInsight() -> String {
        guard filteredAnalyses.count >= 4 else { return "Need more data to analyze improvement" }
        
        let recentQuarter = Array(filteredAnalyses.suffix(filteredAnalyses.count / 4))
        let earlierQuarter = Array(filteredAnalyses.prefix(filteredAnalyses.count / 4))
        
        let recentDeviation = calculateDeviationForAnalyses(recentQuarter)
        let earlierDeviation = calculateDeviationForAnalyses(earlierQuarter)
        
        if recentDeviation < earlierDeviation {
            return "Your tempo consistency is improving over time"
        } else if recentDeviation > earlierDeviation {
            return "Your tempo consistency has room for improvement"
        } else {
            return "Your tempo consistency has been stable"
        }
    }
    
    private func getRecommendation() -> String {
        if averageTempo < 2.0 {
            return "Try slowing down your backswing for better tempo"
        } else if averageTempo > 3.5 {
            return "Focus on a more aggressive downswing transition"
        } else {
            return "Maintain your current tempo with consistent practice"
        }
    }
    
    private func calculateDeviationForAnalyses(_ analyses: [SwingAnalysis]) -> Double {
        guard !analyses.isEmpty else { return 0 }
        let tempos = analyses.map { $0.metrics.tempo }
        let mean = tempos.reduce(0, +) / Double(tempos.count)
        return abs(mean - idealTempo)
    }
}

#Preview {
    NavigationView {
        TempoDashboard(analyses: [])
    }
}
