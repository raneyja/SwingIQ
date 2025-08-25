//
//  HelpTutorialsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct HelpTutorialsView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Getting Started") {
                    NavigationLink(destination: TutorialDetailView(title: "Recording Your First Swing", content: recordingTutorial)) {
                        HStack {
                            Image(systemName: "video.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Recording Your First Swing")
                                Text("Learn how to capture perfect swing videos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: TutorialDetailView(title: "Understanding Analysis Results", content: analysisTutorial)) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Understanding Analysis Results")
                                Text("Interpreting your swing metrics and feedback")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: TutorialDetailView(title: "Setting Up Your Profile", content: profileTutorial)) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Setting Up Your Profile")
                                Text("Customize your settings for better analysis")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Video Tutorials") {
                    VideoTutorialRow(title: "Camera Setup & Positioning", duration: "3:45", level: "Beginner")
                    VideoTutorialRow(title: "Advanced Analysis Features", duration: "5:12", level: "Intermediate")
                    VideoTutorialRow(title: "Tracking Progress Over Time", duration: "4:30", level: "Beginner")
                    VideoTutorialRow(title: "Sharing with Your Coach", duration: "2:15", level: "Beginner")
                    VideoTutorialRow(title: "Customizing Analysis Settings", duration: "6:20", level: "Advanced")
                }
                
                Section("Troubleshooting") {
                    NavigationLink(destination: TroubleshootingView()) {
                        HStack {
                            Image(systemName: "wrench.circle")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Common Issues & Solutions")
                        }
                    }
                    
                    NavigationLink(destination: PerformanceGuideView()) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)
                            Text("Performance & Battery Tips")
                        }
                    }
                }
                
                Section("Frequently Asked Questions") {
                    NavigationLink(destination: FAQView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("View All FAQs")
                        }
                    }
                    
                    DisclosureGroup("How accurate is the swing analysis?") {
                        Text("SwingIQ uses advanced computer vision algorithms to analyze your swing with high accuracy. For best results, ensure good lighting and follow our camera positioning guidelines.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    DisclosureGroup("Can I use SwingIQ indoors?") {
                        Text("Yes! SwingIQ works great indoors with proper lighting. Make sure you have enough space and a clear background for optimal tracking.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    DisclosureGroup("How much storage does SwingIQ use?") {
                        Text("Video storage varies by quality settings. A typical 10-second swing video uses 5-15MB. You can adjust quality in Camera Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Contact & Support") {
                    Button(action: {
                        openSupportEmail()
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Email Support Team")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        openUserGuide()
                    }) {
                        HStack {
                            Image(systemName: "book")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Complete User Guide")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Help & Tutorials")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search help topics...")
        }
    }
    
    // MARK: - Helper Methods
    
    private func openSupportEmail() {
        let email = "support@swingiq.com"
        let subject = "SwingIQ Help Request"
        let body = "Please describe your question or issue:\n\n"
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openUserGuide() {
        if let url = URL(string: "https://swingiq.com/user-guide") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Tutorial Content
    
    private var recordingTutorial: String {
        """
        Recording Your First Swing
        
        1. Camera Position
        Set your device on a stable surface or tripod, positioned to capture your full swing from the side (down-the-line view).
        
        2. Distance & Height
        Place the camera 10-15 feet away from your swing position at chest height for optimal tracking.
        
        3. Lighting
        Ensure good lighting on your swing area. Avoid backlighting or shadows that could interfere with analysis.
        
        4. Background
        Choose a plain background when possible. Avoid busy backgrounds that might confuse the tracking algorithm.
        
        5. Recording
        Tap the record button and take your normal swing. The app will automatically detect and analyze your swing motion.
        
        6. Review
        After recording, review your analysis results and use the playback features to study your technique.
        """
    }
    
    private var analysisTutorial: String {
        """
        Understanding Analysis Results
        
        Swing Tempo
        Shows the timing of your backswing vs downswing. A ratio of 3:1 (backswing:downswing) is typically ideal.
        
        Club Head Speed
        Measured at impact, this indicates the power generation in your swing. Higher speeds generally mean more distance.
        
        Swing Plane
        The path your club takes during the swing. A consistent plane leads to more accurate shots.
        
        Impact Position
        Your body and club position at the moment of impact. This significantly affects ball flight.
        
        Follow Through
        The completion of your swing motion. A balanced follow-through indicates good technique.
        
        Improvement Tips
        Each analysis includes personalized tips based on your specific swing characteristics and areas for improvement.
        """
    }
    
    private var profileTutorial: String {
        """
        Setting Up Your Profile
        
        Personal Information
        Enter your height, dominant hand, and skill level for more accurate analysis and recommendations.
        
        Club Selection
        Set up your clubs with specifications for better distance and trajectory analysis.
        
        Analysis Preferences
        Choose which metrics are most important to you and customize the feedback you receive.
        
        Camera Settings
        Adjust video quality, frame rate, and recording duration based on your needs and device capabilities.
        
        Privacy Settings
        Control who can see your data and whether you want to contribute to algorithm improvements.
        
        Coach Integration
        Connect with your golf instructor to share analysis results and track progress together.
        """
    }
}

// MARK: - Supporting Views

struct VideoTutorialRow: View {
    let title: String
    let duration: String
    let level: String
    
    var body: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                HStack {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(level)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Play video tutorial
        }
    }
}

struct TutorialDetailView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TroubleshootingView: View {
    var body: some View {
        List {
            Section("Camera Issues") {
                DisclosureGroup("Camera won't start") {
                    Text("1. Check camera permissions in iOS Settings\n2. Restart the app\n3. Restart your device if the issue persists")
                        .font(.caption)
                }
                
                DisclosureGroup("Poor video quality") {
                    Text("1. Clean your camera lens\n2. Improve lighting conditions\n3. Check Camera Settings for quality options")
                        .font(.caption)
                }
            }
            
            Section("Analysis Issues") {
                DisclosureGroup("Swing not detected") {
                    Text("1. Ensure you're in the camera frame\n2. Check lighting and background\n3. Make sure you're making a full swing motion")
                        .font(.caption)
                }
                
                DisclosureGroup("Inaccurate results") {
                    Text("1. Verify camera positioning\n2. Check your profile settings\n3. Ensure proper swing technique")
                        .font(.caption)
                }
            }
            
            Section("App Performance") {
                DisclosureGroup("App running slowly") {
                    Text("1. Close other apps\n2. Restart SwingIQ\n3. Check available storage space")
                        .font(.caption)
                }
                
                DisclosureGroup("Crashes or freezing") {
                    Text("1. Update to the latest version\n2. Restart your device\n3. Contact support if issues persist")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Troubleshooting")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceGuideView: View {
    var body: some View {
        List {
            Section("Battery Optimization") {
                Text("• Lower video quality for longer recording sessions")
                Text("• Close other apps while using SwingIQ")
                Text("• Enable Low Power Mode for extended practice")
                Text("• Keep your device plugged in for long sessions")
            }
            
            Section("Storage Management") {
                Text("• Regularly export and delete old analyses")
                Text("• Adjust video quality settings based on needs")
                Text("• Use iCloud sync to free up local storage")
                Text("• Clear cache in Settings if needed")
            }
            
            Section("Best Performance") {
                Text("• Keep SwingIQ updated to the latest version")
                Text("• Restart the app before important sessions")
                Text("• Ensure good WiFi connection for cloud features")
                Text("• Use a tripod for stable video recording")
            }
        }
        .navigationTitle("Performance Tips")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQView: View {
    var body: some View {
        List {
            Section("General") {
                DisclosureGroup("What devices support SwingIQ?") {
                    Text("SwingIQ requires iOS 14.0 or later and works best on iPhone 11 or newer for optimal camera performance.")
                        .font(.caption)
                }
                
                DisclosureGroup("Is SwingIQ free to use?") {
                    Text("SwingIQ offers both free and premium features. Basic swing analysis is free, while advanced features require a subscription.")
                        .font(.caption)
                }
            }
            
            Section("Features") {
                DisclosureGroup("Can I compare multiple swings?") {
                    Text("Yes! Premium users can compare swings side-by-side and track progress over time with detailed analytics.")
                        .font(.caption)
                }
                
                DisclosureGroup("Does SwingIQ work with all clubs?") {
                    Text("SwingIQ analyzes swings with all clubs. You can set specific clubs in your profile for more accurate feedback.")
                        .font(.caption)
                }
            }
            
            Section("Data & Privacy") {
                DisclosureGroup("Where is my data stored?") {
                    Text("Your swing data is stored locally on your device and optionally synced to iCloud. We don't store videos on our servers.")
                        .font(.caption)
                }
                
                DisclosureGroup("Can I export my data?") {
                    Text("Yes, you can export all your swing analysis data in JSON format from Privacy Settings.")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Frequently Asked Questions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HelpTutorialsView()
}
