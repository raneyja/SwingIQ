//
//  SimpleRecordView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVFoundation

struct SimpleRecordView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var videoProcessor = VideoProcessorService()
    @StateObject private var swingDetector = SwingDetectionService()
    
    @State private var showingVideoPicker = false
    @State private var showingSettings = false
    @State private var showingProcessingQueue = false
    @State private var isRecording = false
    @State private var recordingStarted = false
    @State private var swingDetected = false
    @State private var navigateToProcessing = false
    @State private var processingVideoURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Camera preview or placeholder
            ZStack {
                if cameraService.isCameraAuthorized && !isRecording {
                    // Static camera preview
                    CameraPreview(session: cameraService.session)
                        .onAppear {
                            cameraService.startSession()
                        }
                        .onDisappear {
                            cameraService.stopSession()
                        }
                } else if isRecording {
                    // Recording view
                    recordingView
                } else {
                    // Permission view
                    cameraPermissionView
                }
                
                // Recording overlay
                if isRecording {
                    recordingOverlay
                }
            }
            .frame(maxHeight: .infinity)
            
            // Bottom controls
            VStack(spacing: 24) {

                
                // Main action buttons
                actionButtons
            }
            .padding()
            .background(Color.black)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Settings") {
                    showingSettings = true
                }
            }
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerWithTrimView { url in
                processVideo(url: url)
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsView
        }
        .sheet(isPresented: $showingProcessingQueue) {
            ProcessingQueueView()
                .environmentObject(videoProcessor)
        }
        .navigationDestination(isPresented: $navigateToProcessing) {
            VideoProcessingView(videoURL: processingVideoURL ?? URL(string: "file://")!, onNavigateToHome: {
                // Default behavior - just dismiss
            })
                .environmentObject(videoProcessor)
        }
        .alert("Camera Error", isPresented: $cameraService.showAlert) {
            Button("OK") { }
        } message: {
            Text(cameraService.alertError.message)
        }
        .onAppear {
            setupSwingDetection()
        }
    }
    
    // MARK: - Recording View
    
    private var recordingView: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
            
            // Swing detection indicator
            if swingDetected {
                VStack {
                    Spacer()
                    Text("SWING DETECTED!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    Spacer()
                }
            }
        }
    }
    
    private var recordingOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                // Recording indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .scaleEffect(recordingStarted ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: recordingStarted)
                    
                    Text("RECORDING")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .padding()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
    VStack(spacing: 12) {
    // Live recording button
    Button(action: startLiveRecording) {
    HStack(spacing: 8) {
    Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
    .font(.title3)
    
    Text(isRecording ? "Stop Recording" : "Record Live Swing")
    .font(.subheadline)
    .fontWeight(.semibold)
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity, maxHeight: 44)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(isRecording ? Color.red : Color.blue)
        .cornerRadius(10)
    }
    .disabled(!cameraService.isCameraAuthorized)
    
    // Upload video button
    Button(action: {
        showingVideoPicker = true
    }) {
    HStack(spacing: 8) {
    Image(systemName: "folder.badge.plus")
        .font(.title3)
    
    Text("Upload Video")
    .font(.subheadline)
            .fontWeight(.semibold)
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity, maxHeight: 44)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
        .background(Color.green)
            .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Processing Queue Indicator
    
    private var processingQueueIndicator: some View {
        Button(action: {
            showingProcessingQueue = true
        }) {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(videoProcessor.isProcessing ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: videoProcessor.isProcessing)
                
                Text("Processing: \(videoProcessor.processingVideos.count) video\(videoProcessor.processingVideos.count == 1 ? "" : "s")")
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Camera Permission View
    
    private var cameraPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.headline)
            
            Text("Please enable camera access to record golf swings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        NavigationView {
            List {
                Section("Camera") {
                    HStack {
                        Text("Authorization")
                        Spacer()
                        Text(cameraService.isCameraAuthorized ? "Granted" : "Denied")
                            .foregroundColor(cameraService.isCameraAuthorized ? .green : .red)
                    }
                }
                
                Section("Processing") {
                    HStack {
                        Text("Videos in Queue")
                        Spacer()
                        Text("\(videoProcessor.processingVideos.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Processing Queue") {
                        videoProcessor.clearQueue()
                    }
                    .foregroundColor(.red)
                    .disabled(videoProcessor.processingVideos.isEmpty)
                }
                
                Section("Swing Detection") {
                    Toggle("Auto-trigger Recording", isOn: $swingDetector.autoTriggerEnabled)
                    
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        Text(swingDetector.sensitivityLevel.rawValue)
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
    
    private func setupSwingDetection() {
        swingDetector.setSwingDetectedCallback {
            DispatchQueue.main.async {
                self.swingDetected = true
                if self.isRecording {
                    self.stopRecordingAndProcess()
                }
            }
        }
    }
    
    private func startLiveRecording() {
        if isRecording {
            stopRecordingAndProcess()
        } else {
            isRecording = true
            recordingStarted = true
            swingDetected = false
            
            cameraService.startRecording()
            swingDetector.startDetection()
        }
    }
    
    private func stopRecordingAndProcess() {
        isRecording = false
        recordingStarted = false
        
        cameraService.stopRecording()
        swingDetector.stopDetection()
        
        // Process the recorded video
        if let videoURL = cameraService.recordedVideoURL {
            processVideo(url: videoURL)
        }
    }
    
    private func processVideo(url: URL) {
        print("📱 Processing video: \(url)")
        videoProcessor.processVideo(url: url)
        processingVideoURL = url
        navigateToProcessing = true
    }
}

// MARK: - Preview

struct SimpleRecordView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleRecordView()
    }
}
