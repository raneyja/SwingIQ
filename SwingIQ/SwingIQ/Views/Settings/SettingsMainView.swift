//
//  SettingsMainView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct SettingsMainView: View {
    @StateObject private var swingAnalyzer = SwingAnalyzerAgent()
    @StateObject private var exportService = JSONExportService()
    @State private var showingExportAlert = false
    @State private var showingClearAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Account & Profile Section
                Section("Account & Profile") {
                    NavigationLink(destination: ProfileManagementView()) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Profile Management")
                        }
                    }
                    
                    NavigationLink(destination: AccountTypeView()) {
                        HStack {
                            Image(systemName: "star.circle")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            Text("Account Type")
                        }
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "lock.circle")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Privacy Settings")
                        }
                    }
                    
                    NavigationLink(destination: ConnectedAccountsView()) {
                        HStack {
                            Image(systemName: "link.circle")
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)
                            Text("Connected Accounts")
                        }
                    }
                }
                
                // Swing Analysis Section
                Section("Swing Analysis") {
                    NavigationLink(destination: CameraSettingsView()) {
                        HStack {
                            Image(systemName: "camera.circle")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Camera Settings")
                        }
                    }
                    
                    NavigationLink(destination: AnalysisPreferencesView()) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Analysis Preferences")
                        }
                    }
                    
                    NavigationLink(destination: MeasurementUnitsView()) {
                        HStack {
                            Image(systemName: "ruler.circle")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            Text("Measurement Units")
                        }
                    }
                    
                    NavigationLink(destination: ClubSelectionView()) {
                        HStack {
                            Image(systemName: "sportscourt.circle")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Club Selection")
                        }
                    }
                }
                
                // Notifications & Alerts Section
                Section("Notifications & Alerts") {
                    NavigationLink(destination: PushNotificationsView()) {
                        HStack {
                            Image(systemName: "bell.circle")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Push Notifications")
                        }
                    }
                    
                    NavigationLink(destination: AchievementNotificationsView()) {
                        HStack {
                            Image(systemName: "trophy.circle")
                                .foregroundColor(.yellow)
                                .frame(width: 24, height: 24)
                            Text("Achievement Notifications")
                        }
                    }
                }
                
                // Support & Legal Section
                Section("Support & Legal") {
                    NavigationLink(destination: HelpTutorialsView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Help & Tutorials")
                        }
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        HStack {
                            Image(systemName: "envelope.circle")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Contact Support")
                        }
                    }
                    
                    NavigationLink(destination: LegalView()) {
                        HStack {
                            Image(systemName: "doc.text.circle")
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                            Text("Legal")
                        }
                    }
                }
                
                // Legacy Data Section (from existing settings)
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
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                    .disabled(swingAnalyzer.analysisHistory.isEmpty)
                }
                
                // About Section
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
            .navigationBarTitleDisplayMode(.large)
            .alert("Export Result", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Clear All Data", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your swing analysis data. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func exportAllData() {
        Task {
            do {
                let _ = try await exportService.exportMultipleAnalyses(swingAnalyzer.analysisHistory)
                await MainActor.run {
                    alertMessage = "Data exported successfully!"
                    showingExportAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Export failed: \(error.localizedDescription)"
                    showingExportAlert = true
                }
            }
        }
    }
    
    private func clearAllData() {
        swingAnalyzer.analysisHistory.removeAll()
    }
}

#Preview {
    SettingsMainView()
}
