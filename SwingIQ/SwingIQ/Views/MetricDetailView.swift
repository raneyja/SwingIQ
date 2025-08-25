//
//  MetricDetailView.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//

import SwiftUI
import Charts

struct MetricDetailView: View {
    let metric: SwingAnalysisDashboard.MetricType
    let analyses: [SwingAnalysis]
    @Environment(\.dismiss) private var dismiss
    
    private var metricValues: [(Date, Double)] {
        analyses.map { analysis in
            let value: Double
            switch metric {
            case .overall:
                value = analysis.scores.overall * 100
            case .balance:
                value = analysis.scores.balance * 100
            case .tempo:
                value = analysis.scores.tempo * 100
            }
            return (analysis.timestamp, value)
        }.sorted { $0.0 < $1.0 }
    }
    
    private var averageValue: Double {
        guard !metricValues.isEmpty else { return 0 }
        return metricValues.map { $0.1 }.reduce(0, +) / Double(metricValues.count)
    }
    
    private var bestValue: Double {
        metricValues.map { $0.1 }.max() ?? 0
    }
    
    private var improvementTrend: Double {
        guard metricValues.count >= 2 else { return 0 }
        let recent = Array(metricValues.suffix(3)).map { $0.1 }
        let earlier = Array(metricValues.prefix(3)).map { $0.1 }
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)
        
        return recentAvg - earlierAvg
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header stats
                    headerStatsSection
                    
                    // Trend chart
                    trendChartSection
                    
                    // Insights
                    insightsSection
                    
                    // Session breakdown
                    sessionBreakdownSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(metric.rawValue)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStatsSection: some View {
        HStack(spacing: 20) {
            statCard(title: "Average", value: averageValue, color: .blue)
            statCard(title: "Best", value: bestValue, color: .green)
            statCard(title: "Trend", value: improvementTrend, color: improvementTrend >= 0 ? .green : .red, showTrend: true)
        }
    }
    
    private func statCard(title: String, value: Double, color: Color, showTrend: Bool = false) -> some View {
        VStack(spacing: 8) {
            if showTrend {
                HStack(spacing: 4) {
                    Image(systemName: value >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(color)
                        .font(.caption)
                    
                    Text(String(format: "%.1f", abs(value)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            } else {
                Text(String(format: "%.1f", value))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Trend Chart
    
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Over Time")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(metricValues.enumerated()), id: \.0) { index, value in
                        LineMark(
                            x: .value("Session", index),
                            y: .value("Score", value.1)
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle())
                        
                        AreaMark(
                            x: .value("Session", index),
                            y: .value("Score", value.1)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                    
                    // Average line
                    RuleMark(y: .value("Average", averageValue))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .chartYScale(domain: [0, 100])
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("Chart requires iOS 16+")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend Analysis",
                    description: getTrendInsight(),
                    color: improvementTrend >= 0 ? .green : .orange
                )
                
                insightCard(
                    icon: "target",
                    title: "Performance Level",
                    description: getPerformanceInsight(),
                    color: .blue
                )
                
                insightCard(
                    icon: "lightbulb",
                    title: "Recommendation",
                    description: getRecommendation(),
                    color: .purple
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
    
    // MARK: - Session Breakdown
    
    private var sessionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Session History")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(metricValues.count) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(metricValues.reversed().enumerated()), id: \.0) { index, value in
                    sessionRow(date: value.0, score: value.1, rank: index + 1)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func sessionRow(date: Date, score: Double, rank: Int) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(String(format: "%.1f", score))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(scoreColor(score))
            
            // Performance indicator
            Image(systemName: getPerformanceIcon(score: score))
                .foregroundColor(scoreColor(score))
                .font(.caption)
        }
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
    
    private func getPerformanceIcon(score: Double) -> String {
        switch score {
        case 80...:
            return "star.fill"
        case 60..<80:
            return "circle.fill"
        default:
            return "triangle.fill"
        }
    }
    
    private func getTrendInsight() -> String {
        if improvementTrend > 5 {
            return "Excellent improvement! Your \(metric.rawValue.lowercased()) is trending upward."
        } else if improvementTrend > 0 {
            return "Slight improvement in your \(metric.rawValue.lowercased()). Keep practicing!"
        } else if improvementTrend > -5 {
            return "Your \(metric.rawValue.lowercased()) has been stable recently."
        } else {
            return "Focus on fundamentals to improve your \(metric.rawValue.lowercased())."
        }
    }
    
    private func getPerformanceInsight() -> String {
        switch averageValue {
        case 80...:
            return "Excellent \(metric.rawValue.lowercased()) performance. You're in the top tier!"
        case 60..<80:
            return "Good \(metric.rawValue.lowercased()) with room for improvement."
        default:
            return "Focus on developing your \(metric.rawValue.lowercased()) fundamentals."
        }
    }
    
    private func getRecommendation() -> String {
        switch metric {
        case .overall:
            if averageValue < 60 {
                return "Work on fundamental swing mechanics and posture"
            } else if averageValue < 80 {
                return "Focus on consistency and timing improvements"
            } else {
                return "Maintain your excellent form with regular practice"
            }
        case .balance:
            if averageValue < 60 {
                return "Practice stability exercises and core strengthening"
            } else if averageValue < 80 {
                return "Work on weight transfer and foot positioning"
            } else {
                return "Excellent balance! Focus on maintaining this stability"
            }
        case .tempo:
            if averageValue < 60 {
                return "Focus on developing a repeatable swing sequence"
            } else if averageValue < 80 {
                return "Practice tempo and rhythm for better consistency"
            } else {
                return "Great consistency! Work on fine-tuning for peak performance"
            }
        }
    }
}

#Preview {
    MetricDetailView(
        metric: .balance,
        analyses: []
    )
}
