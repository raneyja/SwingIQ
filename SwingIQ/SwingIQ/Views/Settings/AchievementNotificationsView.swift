//
//  AchievementNotificationsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct AchievementNotificationsView: View {
    @State private var achievementsEnabled = true
    @State private var personalBests = true
    @State private var milestoneAlerts = true
    @State private var streakNotifications = true
    @State private var weeklyRecaps = true
    @State private var challengeCompletions = true
    @State private var socialSharing = false
    @State private var levelUpAlerts = true
    @State private var badgeUnlocks = true
    
    @State private var swingSpeedPBs = true
    @State private var consistencyPBs = true
    @State private var accuracyPBs = true
    @State private var tempoImprovements = true
    @State private var overallScoreImprovements = true
    
    @State private var practiceStreakGoal = "7 days"
    @State private var sessionCountMilestones = true
    @State private var improvementPercentage = "5%"
    @State private var celebrationStyle = "Immediate"
    @State private var sharingFrequency = "Major milestones only"
    
    let streakGoalOptions = ["3 days", "7 days", "14 days", "30 days", "Custom"]
    let improvementOptions = ["1%", "5%", "10%", "15%", "20%"]
    let celebrationOptions = ["Immediate", "End of session", "Daily summary", "Weekly summary"]
    let sharingOptions = ["Never", "Personal bests only", "Major milestones only", "All achievements"]
    
    var body: some View {
        NavigationView {
            List {
                Section("General Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Achievement Notifications", isOn: $achievementsEnabled)
                        
                        Text("Get notified about your golf progress and achievements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if achievementsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Celebration Style")
                                Spacer()
                                Picker("Style", selection: $celebrationStyle) {
                                    ForEach(celebrationOptions, id: \.self) { style in
                                        Text(style).tag(style)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("When to notify about achievements")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Personal Bests") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Personal Best Alerts", isOn: $personalBests)
                        
                        Text("Celebrate when you beat your previous records")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    if personalBests && achievementsEnabled {
                        Group {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Swing Speed Records", isOn: $swingSpeedPBs)
                                
                                Text("New club head speed personal bests")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Consistency Records", isOn: $consistencyPBs)
                                
                                Text("Best consistency scores and improvements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Accuracy Records", isOn: $accuracyPBs)
                                
                                Text("Best accuracy measurements and improvements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Tempo Improvements", isOn: $tempoImprovements)
                                
                                Text("Best tempo consistency and timing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Overall Score Improvements", isOn: $overallScoreImprovements)
                                
                                Text("Combined swing analysis score improvements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    if personalBests && achievementsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Improvement Threshold")
                                Spacer()
                                Picker("Percentage", selection: $improvementPercentage) {
                                    ForEach(improvementOptions, id: \.self) { percentage in
                                        Text(percentage).tag(percentage)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("Minimum improvement to trigger notification")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Milestones & Goals") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Milestone Celebrations", isOn: $milestoneAlerts)
                        
                        Text("Major achievement milestones and goals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Practice Streak Tracking", isOn: $streakNotifications)
                        
                        Text("Celebrate consistent practice habits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    if streakNotifications && achievementsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Streak Goal")
                                Spacer()
                                Picker("Goal", selection: $practiceStreakGoal) {
                                    ForEach(streakGoalOptions, id: \.self) { goal in
                                        Text(goal).tag(goal)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("Practice streak milestone to celebrate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Session Count Milestones", isOn: $sessionCountMilestones)
                        
                        Text("Celebrate analysis session milestones (10th, 50th, 100th, etc.)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Challenge Completions", isOn: $challengeCompletions)
                        
                        Text("Completed training challenges and goals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                }
                
                Section("Progress & Badges") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Level Up Alerts", isOn: $levelUpAlerts)
                        
                        Text("Notify when advancing to new skill levels")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Badge Unlocks", isOn: $badgeUnlocks)
                        
                        Text("New achievement badges and awards")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Weekly Progress Recaps", isOn: $weeklyRecaps)
                        
                        Text("Summary of your week's improvements and achievements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                }
                
                Section("Social & Sharing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Social Sharing", isOn: $socialSharing)
                        
                        Text("Option to share achievements on social media")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!achievementsEnabled)
                    
                    if socialSharing && achievementsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sharing Frequency")
                                Spacer()
                                Picker("Frequency", selection: $sharingFrequency) {
                                    ForEach(sharingOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("Which achievements to suggest sharing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Advanced") {
                    NavigationLink("Custom Achievement Goals") {
                        CustomGoalsView()
                    }
                    .disabled(!achievementsEnabled)
                    
                    NavigationLink("Achievement History") {
                        AchievementHistoryView()
                    }
                    .disabled(!achievementsEnabled)
                }
            }
            .navigationTitle("Achievement Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAchievementSettings()
            }
            .onChange(of: achievementsEnabled) { _ in saveAchievementSettings() }
            .onChange(of: personalBests) { _ in saveAchievementSettings() }
            .onChange(of: milestoneAlerts) { _ in saveAchievementSettings() }
            .onChange(of: streakNotifications) { _ in saveAchievementSettings() }
            .onChange(of: weeklyRecaps) { _ in saveAchievementSettings() }
            .onChange(of: challengeCompletions) { _ in saveAchievementSettings() }
            .onChange(of: socialSharing) { _ in saveAchievementSettings() }
            .onChange(of: levelUpAlerts) { _ in saveAchievementSettings() }
            .onChange(of: badgeUnlocks) { _ in saveAchievementSettings() }
            .onChange(of: swingSpeedPBs) { _ in saveAchievementSettings() }
            .onChange(of: consistencyPBs) { _ in saveAchievementSettings() }
            .onChange(of: accuracyPBs) { _ in saveAchievementSettings() }
            .onChange(of: tempoImprovements) { _ in saveAchievementSettings() }
            .onChange(of: overallScoreImprovements) { _ in saveAchievementSettings() }
            .onChange(of: practiceStreakGoal) { _ in saveAchievementSettings() }
            .onChange(of: sessionCountMilestones) { _ in saveAchievementSettings() }
            .onChange(of: improvementPercentage) { _ in saveAchievementSettings() }
            .onChange(of: celebrationStyle) { _ in saveAchievementSettings() }
            .onChange(of: sharingFrequency) { _ in saveAchievementSettings() }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAchievementSettings() {
        achievementsEnabled = UserDefaults.standard.object(forKey: "achievementsEnabled") != nil ? UserDefaults.standard.bool(forKey: "achievementsEnabled") : true
        personalBests = UserDefaults.standard.object(forKey: "personalBests") != nil ? UserDefaults.standard.bool(forKey: "personalBests") : true
        milestoneAlerts = UserDefaults.standard.object(forKey: "milestoneAlerts") != nil ? UserDefaults.standard.bool(forKey: "milestoneAlerts") : true
        streakNotifications = UserDefaults.standard.object(forKey: "streakNotifications") != nil ? UserDefaults.standard.bool(forKey: "streakNotifications") : true
        weeklyRecaps = UserDefaults.standard.object(forKey: "weeklyRecaps") != nil ? UserDefaults.standard.bool(forKey: "weeklyRecaps") : true
        challengeCompletions = UserDefaults.standard.object(forKey: "challengeCompletions") != nil ? UserDefaults.standard.bool(forKey: "challengeCompletions") : true
        socialSharing = UserDefaults.standard.bool(forKey: "socialSharing")
        levelUpAlerts = UserDefaults.standard.object(forKey: "levelUpAlerts") != nil ? UserDefaults.standard.bool(forKey: "levelUpAlerts") : true
        badgeUnlocks = UserDefaults.standard.object(forKey: "badgeUnlocks") != nil ? UserDefaults.standard.bool(forKey: "badgeUnlocks") : true
        
        swingSpeedPBs = UserDefaults.standard.object(forKey: "swingSpeedPBs") != nil ? UserDefaults.standard.bool(forKey: "swingSpeedPBs") : true
        consistencyPBs = UserDefaults.standard.object(forKey: "consistencyPBs") != nil ? UserDefaults.standard.bool(forKey: "consistencyPBs") : true
        accuracyPBs = UserDefaults.standard.object(forKey: "accuracyPBs") != nil ? UserDefaults.standard.bool(forKey: "accuracyPBs") : true
        tempoImprovements = UserDefaults.standard.object(forKey: "tempoImprovements") != nil ? UserDefaults.standard.bool(forKey: "tempoImprovements") : true
        overallScoreImprovements = UserDefaults.standard.object(forKey: "overallScoreImprovements") != nil ? UserDefaults.standard.bool(forKey: "overallScoreImprovements") : true
        
        practiceStreakGoal = UserDefaults.standard.string(forKey: "practiceStreakGoal") ?? "7 days"
        sessionCountMilestones = UserDefaults.standard.object(forKey: "sessionCountMilestones") != nil ? UserDefaults.standard.bool(forKey: "sessionCountMilestones") : true
        improvementPercentage = UserDefaults.standard.string(forKey: "improvementPercentage") ?? "5%"
        celebrationStyle = UserDefaults.standard.string(forKey: "celebrationStyle") ?? "Immediate"
        sharingFrequency = UserDefaults.standard.string(forKey: "sharingFrequency") ?? "Major milestones only"
    }
    
    private func saveAchievementSettings() {
        UserDefaults.standard.set(achievementsEnabled, forKey: "achievementsEnabled")
        UserDefaults.standard.set(personalBests, forKey: "personalBests")
        UserDefaults.standard.set(milestoneAlerts, forKey: "milestoneAlerts")
        UserDefaults.standard.set(streakNotifications, forKey: "streakNotifications")
        UserDefaults.standard.set(weeklyRecaps, forKey: "weeklyRecaps")
        UserDefaults.standard.set(challengeCompletions, forKey: "challengeCompletions")
        UserDefaults.standard.set(socialSharing, forKey: "socialSharing")
        UserDefaults.standard.set(levelUpAlerts, forKey: "levelUpAlerts")
        UserDefaults.standard.set(badgeUnlocks, forKey: "badgeUnlocks")
        
        UserDefaults.standard.set(swingSpeedPBs, forKey: "swingSpeedPBs")
        UserDefaults.standard.set(consistencyPBs, forKey: "consistencyPBs")
        UserDefaults.standard.set(accuracyPBs, forKey: "accuracyPBs")
        UserDefaults.standard.set(tempoImprovements, forKey: "tempoImprovements")
        UserDefaults.standard.set(overallScoreImprovements, forKey: "overallScoreImprovements")
        
        UserDefaults.standard.set(practiceStreakGoal, forKey: "practiceStreakGoal")
        UserDefaults.standard.set(sessionCountMilestones, forKey: "sessionCountMilestones")
        UserDefaults.standard.set(improvementPercentage, forKey: "improvementPercentage")
        UserDefaults.standard.set(celebrationStyle, forKey: "celebrationStyle")
        UserDefaults.standard.set(sharingFrequency, forKey: "sharingFrequency")
    }
}

// MARK: - Supporting Views

struct CustomGoalsView: View {
    @State private var customGoals: [String] = ["Break 100 mph swing speed", "Achieve 90% tempo consistency"]
    @State private var newGoalText = ""
    @State private var showingAddGoal = false
    
    var body: some View {
        List {
            Section("Active Goals") {
                ForEach(customGoals, id: \.self) { goal in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(goal)
                                .font(.body)
                            Text("In Progress")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Button("Edit") {
                            // Edit goal
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .onDelete(perform: deleteGoals)
            }
            
            Section("Create New Goal") {
                HStack {
                    TextField("Enter your achievement goal", text: $newGoalText)
                    Button("Add") {
                        if !newGoalText.isEmpty {
                            customGoals.append(newGoalText)
                            newGoalText = ""
                        }
                    }
                    .disabled(newGoalText.isEmpty)
                }
            }
            
            Section("Suggested Goals") {
                let suggestions = [
                    "Achieve 95% tempo consistency",
                    "Complete 30 practice sessions",
                    "Improve swing speed by 10%",
                    "Master 5 different clubs"
                ]
                
                ForEach(suggestions, id: \.self) { suggestion in
                    HStack {
                        Text(suggestion)
                        Spacer()
                        Button("Add") {
                            customGoals.append(suggestion)
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("Custom Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteGoals(offsets: IndexSet) {
        customGoals.remove(atOffsets: offsets)
    }
}

struct AchievementHistoryView: View {
    @State private var achievements: [(title: String, date: String, type: String)] = [
        ("New Personal Best: 102 mph swing speed", "Today", "Personal Best"),
        ("Practice Streak: 7 days", "Yesterday", "Milestone"),
        ("Consistency Improved: 15%", "2 days ago", "Improvement"),
        ("Badge Unlocked: Speed Demon", "1 week ago", "Badge")
    ]
    
    let achievementTypeColors: [String: Color] = [
        "Personal Best": .green,
        "Milestone": .blue,
        "Improvement": .orange,
        "Badge": .purple
    ]
    
    var body: some View {
        List {
            Section("Recent Achievements") {
                ForEach(achievements, id: \.title) { achievement in
                    HStack {
                        Circle()
                            .fill(achievementTypeColors[achievement.type] ?? .gray)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(achievement.title)
                                .font(.body)
                            
                            HStack {
                                Text(achievement.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(achievement.type)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(achievementTypeColors[achievement.type]?.opacity(0.2) ?? Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Statistics") {
                HStack {
                    Text("Total Achievements")
                    Spacer()
                    Text("\(achievements.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Personal Bests")
                    Spacer()
                    Text("\(achievements.filter { $0.type == "Personal Best" }.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Badges Earned")
                    Spacer()
                    Text("\(achievements.filter { $0.type == "Badge" }.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Achievement History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AchievementNotificationsView()
}
