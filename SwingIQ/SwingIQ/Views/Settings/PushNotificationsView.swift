//
//  PushNotificationsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct PushNotificationsView: View {
    @State private var notificationsEnabled = true
    @State private var roundReminders = true
    @State private var practiceReminders = true
    @State private var tipsNotifications = true
    @State private var achievementAlerts = true
    @State private var progressUpdates = true
    @State private var weatherAlerts = true
    @State private var equipmentReminders = false
    
    @State private var roundReminderTime = "1 hour"
    @State private var practiceFrequency = "Every 3 days"
    @State private var tipsFrequency = "Daily"
    @State private var quietHoursEnabled = true
    @State private var quietStartTime = "10:00 PM"
    @State private var quietEndTime = "7:00 AM"
    
    let reminderTimeOptions = ["30 minutes", "1 hour", "2 hours", "1 day"]
    let practiceFrequencyOptions = ["Daily", "Every 2 days", "Every 3 days", "Weekly", "Never"]
    let tipsFrequencyOptions = ["Daily", "Every 2 days", "Weekly", "Monthly", "Never"]
    let timeOptions = ["6:00 AM", "7:00 AM", "8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM", "11:00 PM"]
    
    var body: some View {
        NavigationView {
            List {
                Section("General") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        
                        Text("Allow SwingIQ to send push notifications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Round & Practice") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Round Reminders", isOn: $roundReminders)
                        
                        Text("Get reminded before scheduled rounds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                    
                    if roundReminders {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Remind me")
                                Spacer()
                                Picker("Time", selection: $roundReminderTime) {
                                    ForEach(reminderTimeOptions, id: \.self) { time in
                                        Text(time).tag(time)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("How long before your scheduled round")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Practice Reminders", isOn: $practiceReminders)
                        
                        Text("Gentle reminders to practice your swing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                    
                    if practiceReminders {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Practice Frequency")
                                Spacer()
                                Picker("Frequency", selection: $practiceFrequency) {
                                    ForEach(practiceFrequencyOptions, id: \.self) { frequency in
                                        Text(frequency).tag(frequency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("How often to remind you to practice")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                    }
                }
                
                Section("Coaching & Tips") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Daily Tips", isOn: $tipsNotifications)
                        
                        Text("Receive golf tips and technique advice")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                    
                    if tipsNotifications {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Tips Frequency")
                                Spacer()
                                Picker("Frequency", selection: $tipsFrequency) {
                                    ForEach(tipsFrequencyOptions, id: \.self) { frequency in
                                        Text(frequency).tag(frequency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("How often to receive coaching tips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Progress Updates", isOn: $progressUpdates)
                        
                        Text("Weekly summaries of your improvement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                }
                
                Section("Achievements & Alerts") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Achievement Alerts", isOn: $achievementAlerts)
                        
                        Text("Instant notifications for personal bests and milestones")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Weather Alerts", isOn: $weatherAlerts)
                        
                        Text("Get notified about ideal golf weather conditions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Equipment Reminders", isOn: $equipmentReminders)
                        
                        Text("Reminders for club maintenance and equipment checks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                }
                
                Section("Quiet Hours") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                        
                        Text("Pause notifications during specified hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .disabled(!notificationsEnabled)
                    
                    if quietHoursEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Start Time")
                                Spacer()
                                Picker("Start", selection: $quietStartTime) {
                                    ForEach(timeOptions, id: \.self) { time in
                                        Text(time).tag(time)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("When to start quiet hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("End Time")
                                Spacer()
                                Picker("End", selection: $quietEndTime) {
                                    ForEach(timeOptions, id: \.self) { time in
                                        Text(time).tag(time)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("When to end quiet hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                    }
                }
                
                Section("Advanced") {
                    NavigationLink("Sound & Vibration") {
                        NotificationSoundView()
                    }
                    .disabled(!notificationsEnabled)
                    
                    NavigationLink("Location-Based") {
                        LocationNotificationsView()
                    }
                    .disabled(!notificationsEnabled)
                }
            }
            .navigationTitle("Push Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadNotificationSettings()
            }
            .onChange(of: notificationsEnabled) { _ in saveNotificationSettings() }
            .onChange(of: roundReminders) { _ in saveNotificationSettings() }
            .onChange(of: practiceReminders) { _ in saveNotificationSettings() }
            .onChange(of: tipsNotifications) { _ in saveNotificationSettings() }
            .onChange(of: achievementAlerts) { _ in saveNotificationSettings() }
            .onChange(of: progressUpdates) { _ in saveNotificationSettings() }
            .onChange(of: weatherAlerts) { _ in saveNotificationSettings() }
            .onChange(of: equipmentReminders) { _ in saveNotificationSettings() }
            .onChange(of: roundReminderTime) { _ in saveNotificationSettings() }
            .onChange(of: practiceFrequency) { _ in saveNotificationSettings() }
            .onChange(of: tipsFrequency) { _ in saveNotificationSettings() }
            .onChange(of: quietHoursEnabled) { _ in saveNotificationSettings() }
            .onChange(of: quietStartTime) { _ in saveNotificationSettings() }
            .onChange(of: quietEndTime) { _ in saveNotificationSettings() }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadNotificationSettings() {
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") != nil ? UserDefaults.standard.bool(forKey: "notificationsEnabled") : true
        roundReminders = UserDefaults.standard.object(forKey: "roundReminders") != nil ? UserDefaults.standard.bool(forKey: "roundReminders") : true
        practiceReminders = UserDefaults.standard.object(forKey: "practiceReminders") != nil ? UserDefaults.standard.bool(forKey: "practiceReminders") : true
        tipsNotifications = UserDefaults.standard.object(forKey: "tipsNotifications") != nil ? UserDefaults.standard.bool(forKey: "tipsNotifications") : true
        achievementAlerts = UserDefaults.standard.object(forKey: "achievementAlerts") != nil ? UserDefaults.standard.bool(forKey: "achievementAlerts") : true
        progressUpdates = UserDefaults.standard.object(forKey: "progressUpdates") != nil ? UserDefaults.standard.bool(forKey: "progressUpdates") : true
        weatherAlerts = UserDefaults.standard.object(forKey: "weatherAlerts") != nil ? UserDefaults.standard.bool(forKey: "weatherAlerts") : true
        equipmentReminders = UserDefaults.standard.bool(forKey: "equipmentReminders")
        
        roundReminderTime = UserDefaults.standard.string(forKey: "roundReminderTime") ?? "1 hour"
        practiceFrequency = UserDefaults.standard.string(forKey: "practiceFrequency") ?? "Every 3 days"
        tipsFrequency = UserDefaults.standard.string(forKey: "tipsFrequency") ?? "Daily"
        quietHoursEnabled = UserDefaults.standard.object(forKey: "quietHoursEnabled") != nil ? UserDefaults.standard.bool(forKey: "quietHoursEnabled") : true
        quietStartTime = UserDefaults.standard.string(forKey: "quietStartTime") ?? "10:00 PM"
        quietEndTime = UserDefaults.standard.string(forKey: "quietEndTime") ?? "7:00 AM"
    }
    
    private func saveNotificationSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(roundReminders, forKey: "roundReminders")
        UserDefaults.standard.set(practiceReminders, forKey: "practiceReminders")
        UserDefaults.standard.set(tipsNotifications, forKey: "tipsNotifications")
        UserDefaults.standard.set(achievementAlerts, forKey: "achievementAlerts")
        UserDefaults.standard.set(progressUpdates, forKey: "progressUpdates")
        UserDefaults.standard.set(weatherAlerts, forKey: "weatherAlerts")
        UserDefaults.standard.set(equipmentReminders, forKey: "equipmentReminders")
        
        UserDefaults.standard.set(roundReminderTime, forKey: "roundReminderTime")
        UserDefaults.standard.set(practiceFrequency, forKey: "practiceFrequency")
        UserDefaults.standard.set(tipsFrequency, forKey: "tipsFrequency")
        UserDefaults.standard.set(quietHoursEnabled, forKey: "quietHoursEnabled")
        UserDefaults.standard.set(quietStartTime, forKey: "quietStartTime")
        UserDefaults.standard.set(quietEndTime, forKey: "quietEndTime")
    }
}

// MARK: - Supporting Views

struct NotificationSoundView: View {
    @State private var soundEnabled = true
    @State private var selectedSound = "Default"
    @State private var vibrationEnabled = true
    @State private var vibrationPattern = "Default"
    
    let soundOptions = ["Default", "Chime", "Bell", "Golf Clap", "Whistle", "Silent"]
    let vibrationOptions = ["Default", "Light", "Medium", "Heavy", "Custom"]
    
    var body: some View {
        List {
            Section("Sound") {
                Toggle("Enable Sound", isOn: $soundEnabled)
                
                if soundEnabled {
                    HStack {
                        Text("Notification Sound")
                        Spacer()
                        Picker("Sound", selection: $selectedSound) {
                            ForEach(soundOptions, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            Section("Vibration") {
                Toggle("Enable Vibration", isOn: $vibrationEnabled)
                
                if vibrationEnabled {
                    HStack {
                        Text("Vibration Pattern")
                        Spacer()
                        Picker("Pattern", selection: $vibrationPattern) {
                            ForEach(vibrationOptions, id: \.self) { pattern in
                                Text(pattern).tag(pattern)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            Section("Test") {
                Button("Test Notification") {
                    // Test notification with current settings
                }
            }
        }
        .navigationTitle("Sound & Vibration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LocationNotificationsView: View {
    @State private var locationEnabled = false
    @State private var courseReminders = true
    @State private var drivingRangeAlerts = true
    @State private var weatherBasedSuggestions = true
    @State private var proximityRadius = "1 mile"
    
    let radiusOptions = ["0.5 miles", "1 mile", "2 miles", "5 miles", "10 miles"]
    
    var body: some View {
        List {
            Section("Location Services") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable Location-Based Notifications", isOn: $locationEnabled)
                    
                    Text("Allow SwingIQ to send notifications based on your location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            if locationEnabled {
                Section("Golf Course Notifications") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Course Reminders", isOn: $courseReminders)
                        
                        Text("Get notified when near favorite golf courses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Driving Range Alerts", isOn: $drivingRangeAlerts)
                        
                        Text("Suggest practice sessions when near driving ranges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Weather-Based Suggestions", isOn: $weatherBasedSuggestions)
                        
                        Text("Notify about good golf weather at nearby courses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Proximity Radius")
                            Spacer()
                            Picker("Radius", selection: $proximityRadius) {
                                ForEach(radiusOptions, id: \.self) { radius in
                                    Text(radius).tag(radius)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("How close to trigger location-based notifications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Location-Based")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PushNotificationsView()
}
