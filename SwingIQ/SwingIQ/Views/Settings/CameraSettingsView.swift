//
//  CameraSettingsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct CameraSettingsView: View {
    @State private var recordingQuality = "1080p"
    @State private var frameRate = 60
    @State private var storageLocation = "Local"
    @State private var autoFocus = true
    @State private var gridLines = true
    @State private var stabilization = true
    @State private var slowMotionMode = true
    @State private var recordingDuration = 10
    @State private var autoStart = false
    @State private var flashMode = "Off"
    @State private var saveTimer: Timer?
    
    let qualityOptions = ["720p", "1080p", "4K"]
    let frameRateOptions = [30, 60, 120, 240]
    let storageOptions = ["Local", "iCloud", "External"]
    let flashOptions = ["Off", "Auto", "On"]
    let durationOptions = [5, 10, 15, 30, 60]
    
    var body: some View {
        List {
                Section("Recording Quality") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Video Quality")
                            Spacer()
                            Picker("Quality", selection: $recordingQuality) {
                                ForEach(qualityOptions, id: \.self) { quality in
                                    Text(quality).tag(quality)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Higher quality provides better analysis but uses more storage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Frame Rate")
                            Spacer()
                            Picker("Frame Rate", selection: $frameRate) {
                                ForEach(frameRateOptions, id: \.self) { rate in
                                    Text("\(rate) fps").tag(rate)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Higher frame rates capture smoother motion for detailed swing analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Camera Features") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Auto Focus", isOn: $autoFocus)
                        
                        Text("Automatically adjust focus during recording for optimal clarity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Grid Lines", isOn: $gridLines)
                        
                        Text("Display alignment grid to help position yourself for recording")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Image Stabilization", isOn: $stabilization)
                        
                        Text("Reduce camera shake for steadier swing recordings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Flash Mode")
                            Spacer()
                            Picker("Flash", selection: $flashMode) {
                                ForEach(flashOptions, id: \.self) { mode in
                                    Text(mode).tag(mode)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Flash settings for low-light recording conditions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Recording Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Slow Motion Mode", isOn: $slowMotionMode)
                        
                        Text("Automatically record in slow motion for detailed swing analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recording Duration")
                            Spacer()
                            Picker("Duration", selection: $recordingDuration) {
                                ForEach(durationOptions, id: \.self) { duration in
                                    Text("\(duration)s").tag(duration)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Default length for swing recordings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Auto-Start Recording", isOn: $autoStart)
                        
                        Text("Begin recording automatically when swing motion is detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Storage") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Storage Location")
                            Spacer()
                            Picker("Storage", selection: $storageLocation) {
                                ForEach(storageOptions, id: \.self) { location in
                                    Text(location).tag(location)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Choose where to save your swing recordings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink("Manage Storage") {
                        StorageManagementView()
                    }
                }
            }
            .navigationTitle("Camera Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCameraSettings()
            }
            .onChange(of: recordingQuality) { _ in debouncedSave() }
            .onChange(of: frameRate) { _ in debouncedSave() }
            .onChange(of: storageLocation) { _ in debouncedSave() }
            .onChange(of: autoFocus) { _ in debouncedSave() }
            .onChange(of: gridLines) { _ in debouncedSave() }
            .onChange(of: stabilization) { _ in debouncedSave() }
            .onChange(of: slowMotionMode) { _ in debouncedSave() }
            .onChange(of: recordingDuration) { _ in debouncedSave() }
            .onChange(of: autoStart) { _ in debouncedSave() }
            .onChange(of: flashMode) { _ in debouncedSave() }
    }
    
    // MARK: - Helper Methods
    
    private func loadCameraSettings() {
        let defaults = UserDefaults.standard
        
        recordingQuality = defaults.string(forKey: "recordingQuality") ?? "1080p"
        frameRate = defaults.object(forKey: "frameRate") != nil ? defaults.integer(forKey: "frameRate") : 60
        storageLocation = defaults.string(forKey: "storageLocation") ?? "Local"
        autoFocus = defaults.object(forKey: "autoFocus") != nil ? defaults.bool(forKey: "autoFocus") : true
        gridLines = defaults.object(forKey: "gridLines") != nil ? defaults.bool(forKey: "gridLines") : true
        stabilization = defaults.object(forKey: "stabilization") != nil ? defaults.bool(forKey: "stabilization") : true
        slowMotionMode = defaults.object(forKey: "slowMotionMode") != nil ? defaults.bool(forKey: "slowMotionMode") : true
        recordingDuration = defaults.object(forKey: "recordingDuration") != nil ? defaults.integer(forKey: "recordingDuration") : 10
        autoStart = defaults.bool(forKey: "autoStart")
        flashMode = defaults.string(forKey: "flashMode") ?? "Off"
    }
    
    private func debouncedSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            saveCameraSettings()
        }
    }
    
    private func saveCameraSettings() {
        let defaults = UserDefaults.standard
        defaults.set(recordingQuality, forKey: "recordingQuality")
        defaults.set(frameRate, forKey: "frameRate")
        defaults.set(storageLocation, forKey: "storageLocation")
        defaults.set(autoFocus, forKey: "autoFocus")
        defaults.set(gridLines, forKey: "gridLines")
        defaults.set(stabilization, forKey: "stabilization")
        defaults.set(slowMotionMode, forKey: "slowMotionMode")
        defaults.set(recordingDuration, forKey: "recordingDuration")
        defaults.set(autoStart, forKey: "autoStart")
        defaults.set(flashMode, forKey: "flashMode")
    }
}

// MARK: - Supporting Views

struct StorageManagementView: View {
    @State private var usedStorage = "2.3 GB"
    @State private var availableStorage = "12.7 GB"
    
    var body: some View {
        List {
            Section("Storage Usage") {
                HStack {
                    Text("Used")
                    Spacer()
                    Text(usedStorage)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Available")
                    Spacer()
                    Text(availableStorage)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Storage Options") {
                Button("Clear Cache") {
                    // Clear temporary files and cache
                }
                
                Button("Archive Old Recordings") {
                    // Move old recordings to archive
                }
                
                Button("Delete Old Recordings") {
                    // Delete recordings older than selected period
                }
                .foregroundColor(.red)
            }
            
            Section("Auto-Cleanup") {
                NavigationLink("Auto-Delete Settings") {
                    AutoDeleteSettingsView()
                }
            }
        }
        .navigationTitle("Storage Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AutoDeleteSettingsView: View {
    @State private var autoDelete = false
    @State private var deletePeriod = "90 days"
    
    let periodOptions = ["30 days", "60 days", "90 days", "6 months", "1 year"]
    
    var body: some View {
        List {
            Section("Auto-Delete") {
                Toggle("Enable Auto-Delete", isOn: $autoDelete)
                
                if autoDelete {
                    HStack {
                        Text("Delete After")
                        Spacer()
                        Picker("Period", selection: $deletePeriod) {
                            ForEach(periodOptions, id: \.self) { period in
                                Text(period).tag(period)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            Section {
                Text("Automatically delete old swing recordings to free up storage space")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Auto-Delete Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CameraSettingsView()
}
