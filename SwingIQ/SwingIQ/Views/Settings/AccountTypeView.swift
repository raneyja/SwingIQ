//
//  AccountTypeView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct AccountTypeView: View {
    @State private var isProUser = false
    @State private var showingUpgradeSheet = false
    @State private var showingBillingSheet = false
    
    var body: some View {
        List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Plan")
                                .font(.headline)
                            Text(isProUser ? "SwingIQ Pro" : "SwingIQ Free")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isProUser ? "star.fill" : "star")
                            .foregroundColor(isProUser ? .yellow : .gray)
                            .font(.title2)
                    }
                    .padding(.vertical, 8)
                }
                
                if !isProUser {
                    Section("Upgrade to Pro") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Unlock Premium Features")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            FeatureRow(icon: "video.fill", title: "Unlimited Video Analysis", isAvailable: false)
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", isAvailable: false)
                            FeatureRow(icon: "icloud.fill", title: "Cloud Sync", isAvailable: false)
                            FeatureRow(icon: "person.2.fill", title: "Share with Coach", isAvailable: false)
                            FeatureRow(icon: "waveform.path.ecg", title: "Detailed Biomechanics", isAvailable: false)
                            
                            Button(action: {
                                showingUpgradeSheet = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Upgrade to Pro")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    Section("Pro Features") {
                        FeatureRow(icon: "video.fill", title: "Unlimited Video Analysis", isAvailable: true)
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", isAvailable: true)
                        FeatureRow(icon: "icloud.fill", title: "Cloud Sync", isAvailable: true)
                        FeatureRow(icon: "person.2.fill", title: "Share with Coach", isAvailable: true)
                        FeatureRow(icon: "waveform.path.ecg", title: "Detailed Biomechanics", isAvailable: true)
                    }
                    
                    Section("Subscription Management") {
                        Button("Manage Billing") {
                            showingBillingSheet = true
                        }
                        
                        Button("Cancel Subscription") {
                            cancelSubscription()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Free Features") {
                    FeatureRow(icon: "video", title: "Basic Video Recording", isAvailable: true)
                    FeatureRow(icon: "chart.bar", title: "Basic Swing Metrics", isAvailable: true)
                    FeatureRow(icon: "calendar", title: "Practice Tracking", isAvailable: true)
                    FeatureRow(icon: "square.and.arrow.up", title: "Export Data", isAvailable: true)
                }
                
                Section("Pricing") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Monthly")
                            Spacer()
                            Text("$9.99/month")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Yearly")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$79.99/year")
                                    .fontWeight(.medium)
                                Text("Save 33%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text("7-day free trial for new users")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Account Type")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingUpgradeSheet) {
                UpgradeSheet(isPresented: $showingUpgradeSheet, onUpgrade: {
                    isProUser = true
                })
            }
            .sheet(isPresented: $showingBillingSheet) {
                BillingSheet(isPresented: $showingBillingSheet)
            }
            .onAppear {
                loadAccountType()
            }
    }
    
    // MARK: - Helper Methods
    
    private func loadAccountType() {
        isProUser = UserDefaults.standard.bool(forKey: "isProUser")
    }
    
    private func cancelSubscription() {
        // Handle subscription cancellation
        isProUser = false
        UserDefaults.standard.set(false, forKey: "isProUser")
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isAvailable ? .blue : .gray)
                .frame(width: 20, height: 20)
            
            Text(title)
                .foregroundColor(isAvailable ? .primary : .secondary)
            
            Spacer()
            
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundColor(isAvailable ? .green : .gray)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Upgrade Sheet

struct UpgradeSheet: View {
    @Binding var isPresented: Bool
    let onUpgrade: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Upgrade to SwingIQ Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unlock advanced swing analysis and take your game to the next level")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 20) {
                    Button("Start Free Trial") {
                        startFreeTrial()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                    
                    Text("7 days free, then $9.99/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func startFreeTrial() {
        onUpgrade()
        UserDefaults.standard.set(true, forKey: "isProUser")
        isPresented = false
    }
}

// MARK: - Billing Sheet

struct BillingSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Billing Management")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Manage your subscription through the App Store")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Open App Store") {
                    openAppStoreSubscriptions()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Billing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func openAppStoreSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    AccountTypeView()
}
