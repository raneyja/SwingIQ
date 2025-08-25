//
//  ContentView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @StateObject private var swingAnalyzer = SwingAnalyzerAgent()
    @StateObject private var exportService = JSONExportService()
    
    @State private var showingAnalysisHistory = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var selectedDashboard: DashboardType? = nil
    @State private var selectedAnalysis: SwingAnalysis? = nil
    
    enum DashboardType: String, CaseIterable, Identifiable {
        case swingAnalysis = "Swing Analysis"
        case progressTracking = "Progress Tracking"
        case practiceActivity = "Practice Activity"
        
        var id: String { self.rawValue }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(0)
            
            NavigationStack {
                WorkingCameraView(onNavigateToHome: {
                    selectedTab = 0 // Navigate to home tab
                })
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "video")
                Text("Record")
            }
            .tag(1)
            
            NavigationStack {
                statsView
                    .navigationTitle("Statistics")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(item: $selectedDashboard) { dashboard in
                        dashboardView(for: dashboard)
                    }
                    .navigationDestination(item: $selectedAnalysis) { analysis in
                        DetailedAnalysisView(analysis: analysis)
                    }
            }
            .tabItem {
                Image(systemName: "chart.bar")
                Text("Stats")
            }
            .tag(2)
            
            NavigationStack {
                SettingsMainView()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .tag(3)
        }
        .onAppear {
            // Configure compact opaque tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Configure normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            // Configure selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Make tab bar more compact
            UITabBar.appearance().itemSpacing = 0
            UITabBar.appearance().itemPositioning = .centered
        }
        .sheet(isPresented: $showingAnalysisHistory) {
            analysisHistoryView
        }
        .sheet(isPresented: $showingSettings) {
            SettingsMainView()
        }
    }
    
       // MARK: - Stats View
    
    private var statsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Dashboard Quick Links
                dashboardLinksSection
                
                // Activity Calendar Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Practice Activity")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    DetailedActivityCalendarView()
                        .padding(.horizontal, 16)
                }
                
                // Analysis History Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(swingAnalyzer.analysisHistory.reversed()) { analysis in
                            analysisHistoryRow(analysis: analysis)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private var dashboardLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Dashboards")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                // All three dashboard cards in a vertical stack
                dashboardCard(type: .swingAnalysis, icon: "figure.golf", color: Color(red: 0.55, green: 0.36, blue: 0.96))
                
                dashboardCard(type: .progressTracking, icon: "chart.line.uptrend.xyaxis", color: Color(red: 0.13, green: 0.59, blue: 0.33))
                
                dashboardCard(type: .practiceActivity, icon: "calendar", color: Color(red: 0.56, green: 0.27, blue: 0.68))
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func dashboardCard(type: DashboardType, icon: String, color: Color) -> some View {
        Button(action: {
            selectedDashboard = type
        }) {
            HStack(spacing: 16) {
                // Icon with colored background circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(getCardDescription(for: type))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func dashboardView(for type: DashboardType) -> some View {
        switch type {
        case .swingAnalysis:
            SwingAnalysisDashboard(analyses: swingAnalyzer.analysisHistory)
        case .progressTracking:
            ProgressTrackingDashboard(analyses: swingAnalyzer.analysisHistory)
        case .practiceActivity:
            PracticeStreakDashboard(analyses: swingAnalyzer.analysisHistory)
        }
    }
 
    
    // MARK: - Analysis History View
    
    private var analysisHistoryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Activity Calendar Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Practice Activity")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    DetailedActivityCalendarView()
                        .padding(.horizontal, 16)
                }
                
                // Analysis History Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(swingAnalyzer.analysisHistory.reversed()) { analysis in
                            analysisHistoryRow(analysis: analysis)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private func analysisHistoryRow(analysis: SwingAnalysis) -> some View {
        Button(action: {
            selectedAnalysis = analysis
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Swing Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", analysis.scores.overall * 100))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(scoreColor(analysis.scores.overall * 100))
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Text(analysis.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    metricBadge(title: "Balance", value: String(format: "%.1f", analysis.scores.balance * 100))
                    metricBadge(title: "Tempo", value: String(format: "%.1f", analysis.scores.tempo * 100))
                    metricBadge(title: "Overall", value: String(format: "%.1f", analysis.scores.overall * 100))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func metricBadge(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        NavigationStack {
            List {
                Section("Data") {
                    HStack {
                        Text("Analysis Sessions")
                        Spacer()
                        Text("\(swingAnalyzer.analysisHistory.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Export All Data") {
                        exportAllData()
                    }
                    .disabled(swingAnalyzer.analysisHistory.isEmpty)
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                    .disabled(swingAnalyzer.analysisHistory.isEmpty)
                }
                
                Section("Features") {
                    NavigationLink("Test MediaPipe", destination: MediaPipeTestView())
                    NavigationLink("3D Visualization", destination: SwingAnalysis3DView())
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.07.19")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCardDescription(for type: DashboardType) -> String {
        switch type {
        case .swingAnalysis:
            let count = swingAnalyzer.analysisHistory.count
            return count > 0 ? "\(count) analysis sessions" : "Start your analysis"
        case .progressTracking:
            if let latest = swingAnalyzer.analysisHistory.last {
                let score = Int(latest.scores.overall * 100)
                return "Current score: \(score)"
            }
            return "Track your improvement"
        case .practiceActivity:
            let recentDays = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let recentSessions = swingAnalyzer.analysisHistory.filter { $0.timestamp >= recentDays }.count
            return recentSessions > 0 ? "\(recentSessions) sessions this week" : "Start practicing"
        }
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
    
    private func exportAllData() {
        Task {
            do {
                let _ = try await exportService.exportMultipleAnalyses(swingAnalyzer.analysisHistory)
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
    
    private func clearAllData() {
        swingAnalyzer.analysisHistory.removeAll()
    }

    // MARK: - Legacy Item Management (keeping for compatibility)
    
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
