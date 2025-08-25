//
//  SwingSpeedDashboard.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import Charts

struct SwingSpeedDashboard: View {
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
    
    private var averageSpeed: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let tempos = filteredAnalyses.map { $0.metrics.tempo }
        return tempos.reduce(0, +) / Double(tempos.count)
    }
    
    private var maxSpeed: Double {
        filteredAnalyses.map { $0.metrics.tempo }.max() ?? 0
    }
    
    private var minSpeed: Double {
        filteredAnalyses.map { $0.metrics.tempo }.min() ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with time range selector
                headerSection
                
                // Speed metrics cards
                metricsCards
                
                // Speed trend chart
                speedTrendChart
                
                // Speed distribution
                speedDistribution
                
                // Performance insights
                performanceInsights
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Swing Speed")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Speed Analysis")
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
            metricCard(title: "Average", value: String(format: "%.1f mph", averageSpeed), color: .blue)
            metricCard(title: "Max", value: String(format: "%.1f mph", maxSpeed), color: .green)
            metricCard(title: "Min", value: String(format: "%.1f mph", minSpeed), color: .orange)
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
    
    // MARK: - Speed Trend Chart
    
    private var speedTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speed Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(filteredAnalyses.enumerated()), id: \.1.id) { index, analysis in
                        LineMark(
                            x: .value("Session", index),
                            y: .value("Tempo", analysis.metrics.tempo)
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle())
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("Speed trend chart requires iOS 16+")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Speed Distribution
    
    private var speedDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speed Distribution")
                .font(.headline)
                .foregroundColor(.primary)
            
            let speedRanges = createSpeedRanges()
            
            VStack(spacing: 8) {
                ForEach(speedRanges, id: \.range) { data in
                    HStack {
                        Text(data.range)
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(.blue)
                                .frame(width: CGFloat(data.percentage) * 200, height: 20)
                        }
                        .cornerRadius(4)
                        
                        Text("\(data.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Speed Trend",
                    description: getSpeedTrendInsight(),
                    color: .green
                )
                
                insightCard(
                    icon: "target",
                    title: "Consistency",
                    description: getConsistencyInsight(),
                    color: .blue
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
    
    private func createSpeedRanges() -> [(range: String, count: Int, percentage: Double)] {
        let speeds = filteredAnalyses.map { $0.metrics.tempo }
        let total = speeds.count
        guard total > 0 else { return [] }
        
        let count80_85 = speeds.filter { $0 >= 80 && $0 < 85 }.count
        let count85_90 = speeds.filter { $0 >= 85 && $0 < 90 }.count
        let count90_95 = speeds.filter { $0 >= 90 && $0 < 95 }.count
        let count95_100 = speeds.filter { $0 >= 95 && $0 < 100 }.count
        let count100Plus = speeds.filter { $0 >= 100 }.count
        
        let ranges = [
            ("80-85", count80_85),
            ("85-90", count85_90),
            ("90-95", count90_95),
            ("95-100", count95_100),
            ("100+", count100Plus)
        ]
        
        return ranges.map { rangeData in
            let count = rangeData.1
            let percentage = Double(count) / Double(total)
            return (range: rangeData.0, count: count, percentage: percentage)
        }
    }
    
    private func getSpeedTrendInsight() -> String {
        guard filteredAnalyses.count >= 2 else { return "Need more data to analyze trends" }
        
        let recentHalf = Array(filteredAnalyses.suffix(filteredAnalyses.count / 2))
        let earlierHalf = Array(filteredAnalyses.prefix(filteredAnalyses.count / 2))
        
        let recentAvg = recentHalf.map { $0.metrics.tempo }.reduce(0, +) / Double(recentHalf.count)
        let earlierAvg = earlierHalf.map { $0.metrics.tempo }.reduce(0, +) / Double(earlierHalf.count)
        
        let change = ((recentAvg - earlierAvg) / earlierAvg) * 100
        
        if change > 2 {
            return String(format: "Your speed improved by %.1f%% recently", change)
        } else if change < -2 {
            return String(format: "Your speed decreased by %.1f%% recently", abs(change))
        } else {
            return "Your speed has been consistent"
        }
    }
    
    private func getConsistencyInsight() -> String {
        guard !filteredAnalyses.isEmpty else { return "No data available" }
        
        let speeds = filteredAnalyses.map { $0.metrics.tempo }
        let mean = speeds.reduce(0, +) / Double(speeds.count)
        let variance = speeds.map { pow($0 - mean, 2) }.reduce(0, +) / Double(speeds.count)
        let standardDeviation = sqrt(variance)
        
        let coefficientOfVariation = (standardDeviation / mean) * 100
        
        if coefficientOfVariation < 5 {
            return "Excellent consistency (±\(String(format: "%.1f", standardDeviation)) mph)"
        } else if coefficientOfVariation < 10 {
            return "Good consistency (±\(String(format: "%.1f", standardDeviation)) mph)"
        } else {
            return "Work on consistency (±\(String(format: "%.1f", standardDeviation)) mph)"
        }
    }
}

#Preview {
    NavigationView {
        SwingSpeedDashboard(analyses: [])
    }
}
