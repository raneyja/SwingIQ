//
//  ConnectedAccountsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct ConnectedAccountsView: View {
    @State private var ghinConnected = false
    @State private var facebookConnected = false
    @State private var twitterConnected = false
    @State private var instagramConnected = false
    @State private var pgatourConnected = false
    @State private var golfClubMembership = ""
    
    var body: some View {
        List {
                Section("Golf Organizations") {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GHIN")
                                .font(.headline)
                            Text("Golf Handicap and Information Network")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if ghinConnected {
                            Button("Disconnect") {
                                disconnectGHIN()
                            }
                            .foregroundColor(.red)
                        } else {
                            Button("Connect") {
                                connectGHIN()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "figure.golf")
                            .foregroundColor(.green)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PGA Tour")
                                .font(.headline)
                            Text("Professional Golfers' Association")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if pgatourConnected {
                            Button("Disconnect") {
                                disconnectPGATour()
                            }
                            .foregroundColor(.red)
                        } else {
                            Button("Connect") {
                                connectPGATour()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Social Media") {
                    SocialAccountRow(
                        platform: "Facebook",
                        icon: "f.circle.fill",
                        color: .blue,
                        isConnected: $facebookConnected,
                        onConnect: connectFacebook,
                        onDisconnect: disconnectFacebook
                    )
                    
                    SocialAccountRow(
                        platform: "Twitter",
                        icon: "bird.fill",
                        color: .cyan,
                        isConnected: $twitterConnected,
                        onConnect: connectTwitter,
                        onDisconnect: disconnectTwitter
                    )
                    
                    SocialAccountRow(
                        platform: "Instagram",
                        icon: "camera.fill",
                        color: .purple,
                        isConnected: $instagramConnected,
                        onConnect: connectInstagram,
                        onDisconnect: disconnectInstagram
                    )
                }
                
                Section("Golf Club Membership") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home Club")
                            .font(.headline)
                        
                        TextField("Enter your golf club name", text: $golfClubMembership)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Connect with other members at your home club")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Connected Apps") {
                    NavigationLink(destination: ConnectedAppsView()) {
                        HStack {
                            Image(systemName: "app.connected.to.app.below.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Third-Party Apps")
                                    .font(.headline)
                                Text("Manage connected golf apps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Account Benefits") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connecting accounts provides:")
                            .font(.headline)
                        
                        BenefitRow(icon: "arrow.triangle.2.circlepath", text: "Automatic handicap sync")
                        BenefitRow(icon: "person.2.fill", text: "Find friends who play golf")
                        BenefitRow(icon: "share.fill", text: "Easy sharing of achievements")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Enhanced statistics")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Connected Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadConnectedAccounts()
            }
            .onChange(of: golfClubMembership) { _ in
                saveGolfClubMembership()
            }
    }
    
    // MARK: - Connection Methods
    
    private func connectGHIN() {
        // Handle GHIN connection
        ghinConnected = true
        saveConnectionStatus("ghinConnected", true)
    }
    
    private func disconnectGHIN() {
        ghinConnected = false
        saveConnectionStatus("ghinConnected", false)
    }
    
    private func connectPGATour() {
        pgatourConnected = true
        saveConnectionStatus("pgatourConnected", true)
    }
    
    private func disconnectPGATour() {
        pgatourConnected = false
        saveConnectionStatus("pgatourConnected", false)
    }
    
    private func connectFacebook() {
        facebookConnected = true
        saveConnectionStatus("facebookConnected", true)
    }
    
    private func disconnectFacebook() {
        facebookConnected = false
        saveConnectionStatus("facebookConnected", false)
    }
    
    private func connectTwitter() {
        twitterConnected = true
        saveConnectionStatus("twitterConnected", true)
    }
    
    private func disconnectTwitter() {
        twitterConnected = false
        saveConnectionStatus("twitterConnected", false)
    }
    
    private func connectInstagram() {
        instagramConnected = true
        saveConnectionStatus("instagramConnected", true)
    }
    
    private func disconnectInstagram() {
        instagramConnected = false
        saveConnectionStatus("instagramConnected", false)
    }
    
    // MARK: - Helper Methods
    
    private func loadConnectedAccounts() {
        ghinConnected = UserDefaults.standard.bool(forKey: "ghinConnected")
        facebookConnected = UserDefaults.standard.bool(forKey: "facebookConnected")
        twitterConnected = UserDefaults.standard.bool(forKey: "twitterConnected")
        instagramConnected = UserDefaults.standard.bool(forKey: "instagramConnected")
        pgatourConnected = UserDefaults.standard.bool(forKey: "pgatourConnected")
        golfClubMembership = UserDefaults.standard.string(forKey: "golfClubMembership") ?? ""
    }
    
    private func saveConnectionStatus(_ key: String, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    private func saveGolfClubMembership() {
        UserDefaults.standard.set(golfClubMembership, forKey: "golfClubMembership")
    }
}

// MARK: - Social Account Row Component

struct SocialAccountRow: View {
    let platform: String
    let icon: String
    let color: Color
    @Binding var isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(platform)
                .font(.headline)
            
            Spacer()
            
            if isConnected {
                Button("Disconnect") {
                    onDisconnect()
                }
                .foregroundColor(.red)
            } else {
                Button("Connect") {
                    onConnect()
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Benefit Row Component

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 16, height: 16)
            
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Connected Apps View

struct ConnectedAppsView: View {
    @State private var golfShotConnected = false
    @State private var arccos18BirdiesConnected = false
    @State private var stravaConnected = false
    
    var body: some View {
        List {
            Section("Golf Apps") {
                ConnectedAppRow(
                    appName: "18Birdies",
                    description: "GPS & Scorecard",
                    icon: "location.fill",
                    color: .green,
                    isConnected: $arccos18BirdiesConnected
                )
                
                ConnectedAppRow(
                    appName: "Golfshot",
                    description: "GPS & Statistics",
                    icon: "target",
                    color: .blue,
                    isConnected: $golfShotConnected
                )
            }
            
            Section("Fitness Apps") {
                ConnectedAppRow(
                    appName: "Strava",
                    description: "Activity Tracking",
                    icon: "figure.walk",
                    color: .orange,
                    isConnected: $stravaConnected
                )
            }
            
            Section("Benefits") {
                Text("Connected apps can share course data, scores, and fitness metrics to provide a more complete picture of your golf performance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Connected Apps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Connected App Row Component

struct ConnectedAppRow: View {
    let appName: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isConnected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isConnected)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConnectedAccountsView()
}
