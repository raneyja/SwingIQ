//
//  AnalysisPreferencesView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct AnalysisPreferencesView: View {
    @State private var showSwingSpeed = true
    @State private var showClubPath = true
    @State private var showFaceAngle = true
    @State private var showTempo = true
    @State private var showBalance = true
    @State private var showSequence = true
    @State private var showImpactPosition = true
    @State private var showFollowThrough = true
    
    @State private var coachingTipsFrequency = "Always"
    @State private var analysisDepth = "Detailed"
    @State private var realTimeAnalysis = true
    @State private var voiceGuidance = false
    @State private var hapticFeedback = true
    @State private var progressTracking = true
    @State private var compareSwings = true
    @State private var aiInsights = true
    
    @State private var focusArea = "Overall"
    @State private var skillLevel = "Intermediate"
    @State private var primaryGoal = "Consistency"
    
    let frequencyOptions = ["Always", "After Each Swing", "End of Session", "Never"]
    let depthOptions = ["Basic", "Detailed", "Professional"]
    let focusOptions = ["Overall", "Driver", "Irons", "Short Game", "Putting"]
    let skillOptions = ["Beginner", "Intermediate", "Advanced", "Professional"]
    let goalOptions = ["Consistency", "Distance", "Accuracy", "Lower Scores", "Specific Fix"]
    
    var body: some View {
        NavigationView {
            List {
                Section("Display Metrics") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Swing Speed", isOn: $showSwingSpeed)
                        
                        Text("Show club head speed at impact")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Club Path", isOn: $showClubPath)
                        
                        Text("Display club path through impact zone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Face Angle", isOn: $showFaceAngle)
                        
                        Text("Show club face angle at impact")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Tempo & Timing", isOn: $showTempo)
                        
                        Text("Analyze swing tempo and timing ratios")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Balance & Weight Shift", isOn: $showBalance)
                        
                        Text("Track weight distribution and balance throughout swing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Swing Sequence", isOn: $showSequence)
                        
                        Text("Show kinetic chain sequence and timing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Impact Position", isOn: $showImpactPosition)
                        
                        Text("Analyze body position at impact")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Follow Through", isOn: $showFollowThrough)
                        
                        Text("Track follow through completion and balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Coaching & Feedback") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Coaching Tips")
                            Spacer()
                            Picker("Frequency", selection: $coachingTipsFrequency) {
                                ForEach(frequencyOptions, id: \.self) { frequency in
                                    Text(frequency).tag(frequency)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("How often to show improvement suggestions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Analysis Depth")
                            Spacer()
                            Picker("Depth", selection: $analysisDepth) {
                                ForEach(depthOptions, id: \.self) { depth in
                                    Text(depth).tag(depth)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Level of detail in swing analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Real-Time Analysis", isOn: $realTimeAnalysis)
                        
                        Text("Show analysis during recording for immediate feedback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Voice Guidance", isOn: $voiceGuidance)
                        
                        Text("Provide audio coaching cues during practice")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        
                        Text("Use device vibration for timing and tempo feedback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Analysis Features") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Progress Tracking", isOn: $progressTracking)
                        
                        Text("Track improvement trends over time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Swing Comparison", isOn: $compareSwings)
                        
                        Text("Compare current swing with previous recordings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("AI Insights", isOn: $aiInsights)
                        
                        Text("Get personalized recommendations from AI analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Personal Profile") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Focus Area")
                            Spacer()
                            Picker("Focus", selection: $focusArea) {
                                ForEach(focusOptions, id: \.self) { focus in
                                    Text(focus).tag(focus)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Primary area of swing improvement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Skill Level")
                            Spacer()
                            Picker("Skill", selection: $skillLevel) {
                                ForEach(skillOptions, id: \.self) { skill in
                                    Text(skill).tag(skill)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Your current golf skill level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Primary Goal")
                            Spacer()
                            Picker("Goal", selection: $primaryGoal) {
                                ForEach(goalOptions, id: \.self) { goal in
                                    Text(goal).tag(goal)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Main objective for swing improvement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Advanced") {
                    NavigationLink("Custom Drills") {
                        CustomDrillsView()
                    }
                    
                    NavigationLink("Analysis Templates") {
                        AnalysisTemplatesView()
                    }
                }
            }
            .navigationTitle("Analysis Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAnalysisSettings()
            }
            .onChange(of: showSwingSpeed) { _ in saveAnalysisSettings() }
            .onChange(of: showClubPath) { _ in saveAnalysisSettings() }
            .onChange(of: showFaceAngle) { _ in saveAnalysisSettings() }
            .onChange(of: showTempo) { _ in saveAnalysisSettings() }
            .onChange(of: showBalance) { _ in saveAnalysisSettings() }
            .onChange(of: showSequence) { _ in saveAnalysisSettings() }
            .onChange(of: showImpactPosition) { _ in saveAnalysisSettings() }
            .onChange(of: showFollowThrough) { _ in saveAnalysisSettings() }
            .onChange(of: coachingTipsFrequency) { _ in saveAnalysisSettings() }
            .onChange(of: analysisDepth) { _ in saveAnalysisSettings() }
            .onChange(of: realTimeAnalysis) { _ in saveAnalysisSettings() }
            .onChange(of: voiceGuidance) { _ in saveAnalysisSettings() }
            .onChange(of: hapticFeedback) { _ in saveAnalysisSettings() }
            .onChange(of: progressTracking) { _ in saveAnalysisSettings() }
            .onChange(of: compareSwings) { _ in saveAnalysisSettings() }
            .onChange(of: aiInsights) { _ in saveAnalysisSettings() }
            .onChange(of: focusArea) { _ in saveAnalysisSettings() }
            .onChange(of: skillLevel) { _ in saveAnalysisSettings() }
            .onChange(of: primaryGoal) { _ in saveAnalysisSettings() }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalysisSettings() {
        showSwingSpeed = UserDefaults.standard.object(forKey: "showSwingSpeed") != nil ? UserDefaults.standard.bool(forKey: "showSwingSpeed") : true
        showClubPath = UserDefaults.standard.object(forKey: "showClubPath") != nil ? UserDefaults.standard.bool(forKey: "showClubPath") : true
        showFaceAngle = UserDefaults.standard.object(forKey: "showFaceAngle") != nil ? UserDefaults.standard.bool(forKey: "showFaceAngle") : true
        showTempo = UserDefaults.standard.object(forKey: "showTempo") != nil ? UserDefaults.standard.bool(forKey: "showTempo") : true
        showBalance = UserDefaults.standard.object(forKey: "showBalance") != nil ? UserDefaults.standard.bool(forKey: "showBalance") : true
        showSequence = UserDefaults.standard.object(forKey: "showSequence") != nil ? UserDefaults.standard.bool(forKey: "showSequence") : true
        showImpactPosition = UserDefaults.standard.object(forKey: "showImpactPosition") != nil ? UserDefaults.standard.bool(forKey: "showImpactPosition") : true
        showFollowThrough = UserDefaults.standard.object(forKey: "showFollowThrough") != nil ? UserDefaults.standard.bool(forKey: "showFollowThrough") : true
        
        coachingTipsFrequency = UserDefaults.standard.string(forKey: "coachingTipsFrequency") ?? "Always"
        analysisDepth = UserDefaults.standard.string(forKey: "analysisDepth") ?? "Detailed"
        realTimeAnalysis = UserDefaults.standard.object(forKey: "realTimeAnalysis") != nil ? UserDefaults.standard.bool(forKey: "realTimeAnalysis") : true
        voiceGuidance = UserDefaults.standard.bool(forKey: "voiceGuidance")
        hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") != nil ? UserDefaults.standard.bool(forKey: "hapticFeedback") : true
        progressTracking = UserDefaults.standard.object(forKey: "progressTracking") != nil ? UserDefaults.standard.bool(forKey: "progressTracking") : true
        compareSwings = UserDefaults.standard.object(forKey: "compareSwings") != nil ? UserDefaults.standard.bool(forKey: "compareSwings") : true
        aiInsights = UserDefaults.standard.object(forKey: "aiInsights") != nil ? UserDefaults.standard.bool(forKey: "aiInsights") : true
        
        focusArea = UserDefaults.standard.string(forKey: "focusArea") ?? "Overall"
        skillLevel = UserDefaults.standard.string(forKey: "skillLevel") ?? "Intermediate"
        primaryGoal = UserDefaults.standard.string(forKey: "primaryGoal") ?? "Consistency"
    }
    
    private func saveAnalysisSettings() {
        UserDefaults.standard.set(showSwingSpeed, forKey: "showSwingSpeed")
        UserDefaults.standard.set(showClubPath, forKey: "showClubPath")
        UserDefaults.standard.set(showFaceAngle, forKey: "showFaceAngle")
        UserDefaults.standard.set(showTempo, forKey: "showTempo")
        UserDefaults.standard.set(showBalance, forKey: "showBalance")
        UserDefaults.standard.set(showSequence, forKey: "showSequence")
        UserDefaults.standard.set(showImpactPosition, forKey: "showImpactPosition")
        UserDefaults.standard.set(showFollowThrough, forKey: "showFollowThrough")
        
        UserDefaults.standard.set(coachingTipsFrequency, forKey: "coachingTipsFrequency")
        UserDefaults.standard.set(analysisDepth, forKey: "analysisDepth")
        UserDefaults.standard.set(realTimeAnalysis, forKey: "realTimeAnalysis")
        UserDefaults.standard.set(voiceGuidance, forKey: "voiceGuidance")
        UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback")
        UserDefaults.standard.set(progressTracking, forKey: "progressTracking")
        UserDefaults.standard.set(compareSwings, forKey: "compareSwings")
        UserDefaults.standard.set(aiInsights, forKey: "aiInsights")
        
        UserDefaults.standard.set(focusArea, forKey: "focusArea")
        UserDefaults.standard.set(skillLevel, forKey: "skillLevel")
        UserDefaults.standard.set(primaryGoal, forKey: "primaryGoal")
    }
}

// MARK: - Supporting Views

struct CustomDrillsView: View {
    @State private var drills: [String] = ["Tempo Drill", "Balance Drill", "Impact Position"]
    
    var body: some View {
        List {
            Section("Available Drills") {
                ForEach(drills, id: \.self) { drill in
                    HStack {
                        Text(drill)
                        Spacer()
                        Button("Configure") {
                            // Configure drill settings
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section("Create New") {
                Button("Add Custom Drill") {
                    // Add new custom drill
                }
            }
        }
        .navigationTitle("Custom Drills")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalysisTemplatesView: View {
    @State private var templates: [String] = ["Quick Analysis", "Full Breakdown", "Competition Mode"]
    
    var body: some View {
        List {
            Section("Analysis Templates") {
                ForEach(templates, id: \.self) { template in
                    HStack {
                        Text(template)
                        Spacer()
                        Button("Edit") {
                            // Edit template
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section("Create New") {
                Button("New Template") {
                    // Create new analysis template
                }
            }
        }
        .navigationTitle("Analysis Templates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AnalysisPreferencesView()
}
