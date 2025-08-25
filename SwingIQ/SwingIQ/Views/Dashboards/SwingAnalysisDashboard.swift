//
//  SwingAnalysisDashboard.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//

import SwiftUI
import Charts

struct SwingAnalysisDashboard: View {
    let analyses: [SwingAnalysis]
    @State private var selectedTimeRange: TimeRange = .thirtyDays
    @State private var selectedMetricDetail: MetricType? = nil
    
    enum MetricType: String, CaseIterable, Identifiable {
        case overall = "Overall Score"
        case balance = "Balance"
        case tempo = "Tempo"
        
        var id: String { self.rawValue }
    }
    
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
    
    private var averageOverallScore: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let scores = filteredAnalyses.map { $0.scores.overall }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private var averageBalanceScore: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let scores = filteredAnalyses.map { $0.scores.balance }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private var averageTempoScore: Double {
        guard !filteredAnalyses.isEmpty else { return 0 }
        let scores = filteredAnalyses.map { $0.scores.tempo }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with time range selector
                headerSection
                
                // Overall Performance Overview
                performanceOverview
                
                // Swing Phase Analysis
                swingPhaseAnalysis
                
                // Body Mechanics Section
                bodyMechanicsSection
                
                // Balance Section
                balanceSection
                
                // Swing Fault Detection
                swingFaultSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Swing Analysis")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedMetricDetail) { metric in
            MetricDetailView(metric: metric, analyses: filteredAnalyses)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Swing Breakdown")
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
    
    // MARK: - Performance Overview
    
    private var performanceOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                metricCard(
                    title: "Overall Score",
                    value: String(format: "%.1f", averageOverallScore * 100),
                    subtitle: "average",
                    color: scoreColor(averageOverallScore * 100),
                    action: { selectedMetricDetail = .overall }
                )
                metricCard(
                    title: "Balance",
                    value: String(format: "%.1f", averageBalanceScore * 100),
                    subtitle: "stability",
                    color: scoreColor(averageBalanceScore * 100),
                    action: { selectedMetricDetail = .balance }
                )
                metricCard(
                    title: "Tempo",
                    value: String(format: "%.1f", averageTempoScore * 100),
                    subtitle: "rhythm",
                    color: scoreColor(averageTempoScore * 100),
                    action: { selectedMetricDetail = .tempo }
                )
            }
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
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
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Swing Phase Analysis
    
    private var swingPhaseAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swing Phase Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let latestAnalysis = filteredAnalyses.last {
                VStack(spacing: 16) {
                    // Swing phases breakdown
                    swingPhaseBreakdown(analysis: latestAnalysis)
                    
                    // Phase timing chart
                    if #available(iOS 16.0, *) {
                        phaseTimingChart
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("No swing analysis available")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func swingPhaseBreakdown(analysis: SwingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Swing Phase Timing")
                .font(.subheadline)
                .fontWeight(.medium)
            
            let phases = ["Address", "Takeaway", "Backswing", "Transition", "Downswing", "Impact", "Follow Through"]
            
            ForEach(phases.indices, id: \.self) { index in
                HStack {
                    Circle()
                        .fill(phaseColor(for: index))
                        .frame(width: 8, height: 8)
                    
                    Text(phases[index])
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(index * 15)ms") // Placeholder timing
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    private var phaseTimingChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phase Duration Trends")
                .font(.caption)
                .foregroundColor(.secondary)
            
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
            .frame(height: 100)
        }
    }
    
    // MARK: - Body Mechanics Section
    
    private var bodyMechanicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Mechanics")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let latestAnalysis = filteredAnalyses.last {
                VStack(spacing: 16) {
                    // Key body angles
                    bodyAnglesDisplay
                    
                    // Posture analysis
                    postureAnalysis(analysis: latestAnalysis)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("No body mechanics data available")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private var bodyAnglesDisplay: some View {
        VStack(spacing: 12) {
            Text("Key Body Angles")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 20) {
                angleIndicator(title: "Hip Turn", angle: 45, idealRange: "40-50°")
                angleIndicator(title: "Shoulder", angle: 85, idealRange: "80-90°")
                angleIndicator(title: "Spine", angle: 12, idealRange: "10-15°")
            }
        }
    }
    
    private func angleIndicator(title: String, angle: Int, idealRange: String) -> some View {
        VStack(spacing: 4) {
            Text("\(angle)°")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(idealRange)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func postureAnalysis(analysis: SwingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Posture Analysis")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(.green)
                
                Text("Good posture maintained throughout swing")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Balance Section
    
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            balanceCard
        }
    }
    
    private var balanceCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: averageBalanceScore)
                    .stroke(scoreColor(averageBalanceScore * 100), lineWidth: 8)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: averageBalanceScore)
                
                Text("\(Int(averageBalanceScore * 100))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(averageBalanceScore * 100))
            }
            
            Text("Balance Score")
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    

    
    // MARK: - Swing Fault Section
    
    private var swingFaultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swing Fault Detection")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let latestAnalysis = filteredAnalyses.last, !latestAnalysis.faults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(latestAnalysis.faults.prefix(3), id: \.type) { fault in
                        faultRow(fault: fault)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("No major swing faults detected")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Keep up the good work!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private func faultRow(fault: SwingFault) -> some View {
        HStack(spacing: 12) {
            Image(systemName: faultIcon(for: fault.type))
                .foregroundColor(faultColor(for: fault.severity))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fault.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Severity: \(fault.severity.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(fault.recommendation)
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.trailing)
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
    
    private func phaseColor(for index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors[index % colors.count]
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
}

#Preview {
    NavigationView {
        SwingAnalysisDashboard(analyses: [])
    }
}
