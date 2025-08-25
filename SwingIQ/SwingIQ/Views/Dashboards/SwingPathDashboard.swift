//
//  SwingPathDashboard.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import Charts

struct SwingPathDashboard: View {
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
    
    private var currentSwingPath: String {
        guard let latest = filteredAnalyses.last else { return "No data" }
        return latest.metrics.swingPathDescription
    }
    
    private var averageDeviation: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let deviations = filteredAnalyses.map { $0.metrics.swingPathDeviation }
        return deviations.reduce(0, +) / Double(deviations.count)
    }
    
    private var swingPlaneConsistency: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let pathDeviations = filteredAnalyses.map { abs($0.metrics.swingPathDeviation) }
        let mean = pathDeviations.reduce(0, +) / Double(pathDeviations.count)
        
        // Convert to consistency score (lower average deviation = higher consistency)
        let consistency = max(0, 100 - (mean * 10))
        return consistency
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with time range selector
                headerSection
                
                // Current status card
                currentStatusCard
                
                // Path metrics cards
                pathMetricsCards
                
                // Swing path trend chart
                swingPathTrendChart
                
                // Path distribution analysis
                pathDistribution
                
                // Swing plane analysis
                swingPlaneAnalysis
                
                // Performance insights
                performanceInsights
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Swing Path")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Path Analysis")
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
    
    // MARK: - Current Status Card
    
    private var currentStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Current Swing Path")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentSwingPath)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(pathColor(currentSwingPath))
                    
                    Text("Most recent analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                pathVisualization
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var pathVisualization: some View {
        ZStack {
            // Target line (ideal path)
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 60, height: 4)
            
            // Actual path indicator
            let deviation = filteredAnalyses.last?.metrics.swingPathDeviation ?? 0
            let offset = min(max(deviation * 3, -25), 25) // Scale and limit offset
            
            Circle()
                .fill(pathColor(currentSwingPath))
                .frame(width: 12, height: 12)
                .offset(x: offset, y: 0)
                .animation(.easeInOut(duration: 0.5), value: offset)
        }
        .frame(width: 80, height: 40)
    }
    
    // MARK: - Path Metrics Cards
    
    private var pathMetricsCards: some View {
        HStack(spacing: 12) {
            metricCard(
                title: "Avg Deviation", 
                value: String(format: "%.1f°", abs(averageDeviation)), 
                subtitle: averageDeviation < 0 ? "inside" : "outside",
                color: .blue
            )
            metricCard(
                title: "Consistency", 
                value: String(format: "%.0f%%", swingPlaneConsistency), 
                subtitle: "swing plane",
                color: swingPlaneConsistency > 80 ? .green : .orange
            )
            metricCard(
                title: "On Plane", 
                value: "\(onPlanePercentage)%", 
                subtitle: "of swings",
                color: .purple
            )
        }
    }
    
    private var onPlanePercentage: Int {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let onPlaneCount = filteredAnalyses.filter { abs($0.metrics.swingPathDeviation) < 2.0 }.count
        return Int((Double(onPlaneCount) / Double(filteredAnalyses.count)) * 100)
    }
    
    private func metricCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title3)
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
    
    // MARK: - Swing Path Trend Chart
    
    private var swingPathTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Path Deviation Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    // Ideal zone (on plane)
                    RectangleMark(
                        xStart: .value("Start", 0),
                        xEnd: .value("End", filteredAnalyses.count),
                        yStart: .value("Lower", -2.0),
                        yEnd: .value("Upper", 2.0)
                    )
                    .foregroundStyle(.green.opacity(0.2))
                    
                    // Zero line
                    RuleMark(y: .value("Ideal", 0))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Actual path deviation
                    ForEach(Array(filteredAnalyses.enumerated()), id: \.1.id) { index, analysis in
                        LineMark(
                            x: .value("Session", index),
                            y: .value("Deviation", analysis.metrics.swingPathDeviation)
                        )
                        .foregroundStyle(.purple)
                        .symbol(Circle())
                    }
                }
                .chartYScale(domain: [-8, 8])
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("Path trend chart requires iOS 16+")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Path Distribution
    
    private var pathDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Path Distribution")
                .font(.headline)
                .foregroundColor(.primary)
            
            let pathCounts = calculatePathDistribution()
            
            VStack(spacing: 12) {
                pathDistributionRow(
                    label: "Inside-Out",
                    count: pathCounts.insideOut,
                    percentage: Double(pathCounts.insideOut) / Double(filteredAnalyses.count),
                    color: .blue
                )
                
                pathDistributionRow(
                    label: "On Plane",
                    count: pathCounts.onPlane,
                    percentage: Double(pathCounts.onPlane) / Double(filteredAnalyses.count),
                    color: .green
                )
                
                pathDistributionRow(
                    label: "Outside-In",
                    count: pathCounts.outsideIn,
                    percentage: Double(pathCounts.outsideIn) / Double(filteredAnalyses.count),
                    color: .red
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func pathDistributionRow(label: String, count: Int, percentage: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                
                Rectangle()
                    .fill(color)
                    .frame(width: percentage * 200, height: 20)
            }
            .cornerRadius(4)
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    // MARK: - Swing Plane Analysis
    
    private var swingPlaneAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swing Plane Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            let planeStats = calculateSwingPlaneStats()
            
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Average Angle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f°", planeStats.average))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Ideal Range")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("45-55°")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Deviation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "±%.1f°", planeStats.standardDeviation))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                // Plane angle visualization
                swingPlaneVisualization(averageAngle: planeStats.average)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func swingPlaneVisualization(averageAngle: Double) -> some View {
        VStack(spacing: 8) {
            Text("Swing Plane Visualization")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                // Background arc (ideal range)
                Path { path in
                    let center = CGPoint(x: 100, y: 100)
                    let radius: CGFloat = 80
                    path.addArc(center: center, radius: radius, 
                               startAngle: .degrees(45), endAngle: .degrees(55), clockwise: false)
                }
                .stroke(Color.green.opacity(0.3), lineWidth: 8)
                
                // Current plane line
                Path { path in
                    let center = CGPoint(x: 100, y: 100)
                    let radius: CGFloat = 80
                    let angle = averageAngle
                    
                    let startPoint = CGPoint(
                        x: center.x + cos(angle * .pi / 180) * 20,
                        y: center.y + sin(angle * .pi / 180) * 20
                    )
                    let endPoint = CGPoint(
                        x: center.x + cos(angle * .pi / 180) * radius,
                        y: center.y + sin(angle * .pi / 180) * radius
                    )
                    
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(Color.blue, lineWidth: 4)
                
                // Angle indicator
                Text(String(format: "%.1f°", averageAngle))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .shadow(radius: 2)
                    )
                    .offset(x: 30, y: -30)
            }
            .frame(width: 200, height: 120)
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
                    icon: "target",
                    title: "Path Quality",
                    description: getPathQualityInsight(),
                    color: .purple
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
    
    private func pathColor(_ pathDescription: String) -> Color {
        switch pathDescription {
        case "On plane":
            return .green
        case "Inside-out":
            return .blue
        case "Outside-in":
            return .red
        default:
            return .gray
        }
    }
    
    private func calculatePathDistribution() -> (insideOut: Int, onPlane: Int, outsideIn: Int) {
        let deviations = filteredAnalyses.map { $0.metrics.swingPathDeviation }
        
        let insideOut = deviations.filter { $0 < -2.0 }.count
        let onPlane = deviations.filter { abs($0) <= 2.0 }.count
        let outsideIn = deviations.filter { $0 > 2.0 }.count
        
        return (insideOut, onPlane, outsideIn)
    }
    
    private func calculateSwingPlaneStats() -> (average: Double, standardDeviation: Double) {
        guard !filteredAnalyses.isEmpty else { return (0, 0) }
        
        let pathDeviations = filteredAnalyses.map { $0.metrics.swingPathDeviation }
        let average = pathDeviations.reduce(0, +) / Double(pathDeviations.count)
        let squaredDiffs = pathDeviations.map { pow($0 - average, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(pathDeviations.count)
        let standardDeviation = sqrt(variance)
        
        return (average, standardDeviation)
    }
    
    private func getPathQualityInsight() -> String {
        let onPlanePercent = onPlanePercentage
        
        if onPlanePercent >= 70 {
            return "Excellent swing path consistency"
        } else if onPlanePercent >= 50 {
            return "Good swing path with room for improvement"
        } else {
            return "Focus on keeping the club on plane"
        }
    }
    
    private func getImprovementInsight() -> String {
        guard filteredAnalyses.count >= 4 else { return "Need more data to analyze improvement" }
        
        let recentQuarter = Array(filteredAnalyses.suffix(filteredAnalyses.count / 4))
        let earlierQuarter = Array(filteredAnalyses.prefix(filteredAnalyses.count / 4))
        
        let recentOnPlane = recentQuarter.filter { abs($0.metrics.swingPathDeviation) < 2.0 }.count
        let earlierOnPlane = earlierQuarter.filter { abs($0.metrics.swingPathDeviation) < 2.0 }.count
        
        let recentPercent = Double(recentOnPlane) / Double(recentQuarter.count) * 100
        let earlierPercent = Double(earlierOnPlane) / Double(earlierQuarter.count) * 100
        
        if recentPercent > earlierPercent + 10 {
            return "Your swing path consistency is improving"
        } else if recentPercent < earlierPercent - 10 {
            return "Work on maintaining consistent swing path"
        } else {
            return "Your swing path consistency has been stable"
        }
    }
    
    private func getRecommendation() -> String {
        let pathCounts = calculatePathDistribution()
        
        if pathCounts.outsideIn > pathCounts.insideOut {
            return "Focus on swinging more from the inside"
        } else if pathCounts.insideOut > pathCounts.outsideIn {
            return "Work on a more neutral swing path"
        } else {
            return "Maintain your current swing path consistency"
        }
    }
}

#Preview {
    NavigationView {
        SwingPathDashboard(analyses: [])
    }
}
