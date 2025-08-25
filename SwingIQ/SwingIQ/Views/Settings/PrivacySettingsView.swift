//
//  PrivacySettingsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct PrivacySettingsView: View {
    @State private var profileVisible = true
    @State private var allowDataSharing = false
    @State private var shareWithCoach = true
    @State private var anonymousAnalytics = true
    @State private var locationTracking = false
    @State private var cloudSync = true
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
                Section("Profile Visibility") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Public Profile", isOn: $profileVisible)
                        
                        Text("Allow other SwingIQ users to view your profile and statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Data Sharing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Share Performance Data", isOn: $allowDataSharing)
                        
                        Text("Allow sharing of anonymized swing data to improve SwingIQ's analysis algorithms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Analytics Data", isOn: $anonymousAnalytics)
                        
                        Text("Help improve SwingIQ by sharing anonymous usage data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Coach & Sharing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Share with Coach", isOn: $shareWithCoach)
                        
                        Text("Allow connected coaches to view your swing analysis and progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink("Manage Coach Access") {
                        CoachAccessView()
                    }
                }
                
                Section("Location & Tracking") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Location Services", isOn: $locationTracking)
                        
                        Text("Allow SwingIQ to access your location for course detection and weather data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink("Location Permissions") {
                        LocationPermissionsView()
                    }
                }
                
                Section("Cloud & Sync") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("iCloud Sync", isOn: $cloudSync)
                        
                        Text("Sync your swing data across all your devices using iCloud")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Data Management") {
                    NavigationLink("Download My Data") {
                        DataExportView()
                    }
                    
                    Button("Delete All Data") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("Privacy Policy") {
                    NavigationLink("View Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    
                    NavigationLink("Data Usage Policy") {
                        DataUsagePolicyView()
                    }
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPrivacySettings()
            }
            .onChange(of: profileVisible) { _ in savePrivacySettings() }
            .onChange(of: allowDataSharing) { _ in savePrivacySettings() }
            .onChange(of: shareWithCoach) { _ in savePrivacySettings() }
            .onChange(of: anonymousAnalytics) { _ in savePrivacySettings() }
            .onChange(of: locationTracking) { _ in savePrivacySettings() }
            .onChange(of: cloudSync) { _ in savePrivacySettings() }
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your personal data, swing analyses, and settings. This action cannot be undone.")
            }
    }
    
    // MARK: - Helper Methods
    
    private func loadPrivacySettings() {
        profileVisible = UserDefaults.standard.bool(forKey: "profileVisible")
        allowDataSharing = UserDefaults.standard.bool(forKey: "allowDataSharing")
        shareWithCoach = UserDefaults.standard.bool(forKey: "shareWithCoach")
        anonymousAnalytics = UserDefaults.standard.bool(forKey: "anonymousAnalytics")
        locationTracking = UserDefaults.standard.bool(forKey: "locationTracking")
        cloudSync = UserDefaults.standard.bool(forKey: "cloudSync")
    }
    
    private func savePrivacySettings() {
        UserDefaults.standard.set(profileVisible, forKey: "profileVisible")
        UserDefaults.standard.set(allowDataSharing, forKey: "allowDataSharing")
        UserDefaults.standard.set(shareWithCoach, forKey: "shareWithCoach")
        UserDefaults.standard.set(anonymousAnalytics, forKey: "anonymousAnalytics")
        UserDefaults.standard.set(locationTracking, forKey: "locationTracking")
        UserDefaults.standard.set(cloudSync, forKey: "cloudSync")
    }
    
    private func deleteAllData() {
        // Show confirmation alert and delete all user data
        // This would include swing analyses, profile data, etc.
    }
}

// MARK: - Supporting Views

struct CoachAccessView: View {
    var body: some View {
        List {
            Section("Connected Coaches") {
                Text("No coaches connected")
                    .foregroundColor(.secondary)
            }
            
            Section("Coach Invitations") {
                Button("Invite Coach") {
                    // Handle coach invitation
                }
            }
        }
        .navigationTitle("Coach Access")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LocationPermissionsView: View {
    var body: some View {
        List {
            Section("Location Access") {
                Text("Location permissions are managed through iOS Settings")
                    .foregroundColor(.secondary)
                
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
        }
        .navigationTitle("Location Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    var body: some View {
        List {
            Section("Export Options") {
                Button("Export Swing Data") {
                    // Export swing analysis data
                }
                
                Button("Export Profile Data") {
                    // Export profile information
                }
                
                Button("Export All Data") {
                    // Export everything
                }
            }
            
            Section("Format") {
                Text("Data will be exported in JSON format")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: July 20, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("SwingIQ Privacy Policy")
                    .font(.headline)
                
                Text("Your privacy is important to us. This privacy policy explains how SwingIQ collects, uses, and protects your information when you use our golf swing analysis app.")
                
                Text("Information We Collect")
                    .font(.headline)
                
                Text("• Video recordings of your golf swings\n• Swing analysis data and metrics\n• Profile information you provide\n• Usage analytics to improve our service")
                
                Text("How We Use Your Information")
                    .font(.headline)
                
                Text("• To provide swing analysis and feedback\n• To track your progress over time\n• To improve our analysis algorithms\n• To provide customer support")
                
                // Add more privacy policy content here
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataUsagePolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Usage Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("How SwingIQ Uses Your Data")
                    .font(.headline)
                
                Text("SwingIQ processes your swing videos locally on your device to analyze your golf technique. No video data is transmitted to our servers unless you explicitly choose to share it.")
                
                Text("Data Storage")
                    .font(.headline)
                
                Text("• Swing videos are stored locally on your device\n• Analysis results are saved to your device and optionally to iCloud\n• Profile data is synchronized across your devices via iCloud")
                
                Text("Data Sharing")
                    .font(.headline)
                
                Text("We only share your data when:\n• You explicitly share analysis with a coach\n• You enable anonymous analytics to help improve SwingIQ\n• Required by law")
                
                // Add more data usage policy content here
            }
            .padding()
        }
        .navigationTitle("Data Usage Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PrivacySettingsView()
}
