//
//  WorkingCameraView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVFoundation

struct WorkingCameraView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var videoProcessor = VideoProcessorService()
    
    // Closure to navigate to home tab
    let onNavigateToHome: () -> Void
    
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var showingVideoPicker = false
    @State private var showingSettings = false
    @State private var navigateToProcessing = false
    @State private var processingVideoURL: URL?
    @State private var showingProcessingView = false
    
    var body: some View {
        ZStack {
            // Full-screen camera background
            Color.black
            
            // Full-screen camera preview
            cameraSection
        }
        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing]) // Avoid bottom to preserve tab bar
        .overlay(alignment: .top) {
            // Top overlay with title and controls
            HStack {
                Text("Record Your Swing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Camera flip button
                Button(action: {
                    print("📱 Flipping camera")
                    cameraService.flipCamera()
                }) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .overlay(alignment: .bottom) {
            // Bottom controls floating over camera view
            bottomControlsSection
                .padding(.bottom, 20) // Just slightly above tab bar
        }
        .onAppear {
            print("📱 WorkingCameraView: View appeared")
            setupCamera()
        }
        .onDisappear {
            cleanup()
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerWithTrimView { url in
                print("📱 WorkingCameraView: Video selected from picker: \(url)")
                processVideo(url: url)
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsView
        }
        .navigationDestination(isPresented: $navigateToProcessing) {
            if let videoURL = processingVideoURL {
                VideoProcessingView(videoURL: videoURL, onNavigateToHome: onNavigateToHome)
                    .environmentObject(videoProcessor)
                    .onAppear {
                        print("📱 WorkingCameraView: VideoProcessingView appeared successfully!")
                    }
            } else {
                VStack {
                    Text("Video not available")
                        .foregroundColor(.white)
                    Button("Go Back") {
                        navigateToProcessing = false
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .fullScreenCover(isPresented: $showingProcessingView) {
            NavigationView {
                if let videoURL = processingVideoURL {
                    VideoProcessingView(videoURL: videoURL, onNavigateToHome: onNavigateToHome)
                        .environmentObject(videoProcessor)
                        .onAppear {
                            print("📱 WorkingCameraView: VideoProcessingView appeared via fullScreenCover!")
                        }
                } else {
                    VStack {
                        Text("Video not available")
                            .foregroundColor(.white)
                        Button("Close") {
                            showingProcessingView = false
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
        }

    }
    
    // MARK: - Camera Section
    
    private var cameraSection: some View {
        ZStack {
            // Camera preview or permission view
            Group {
                if cameraService.isCameraAuthorized {
                    // Camera preview
                    CameraPreview(session: cameraService.session)
                } else {
                    // Permission request view
                    cameraPermissionView
                }
            }
            
            // Recording overlay
            if isRecording {
                recordingOverlay
            }
        }
    }
    
    private var cameraPermissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("SwingIQ needs camera access to record your golf swings for analysis.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 32)
            }
            
            Button("Enable Camera Access") {
                print("📱 Opening settings for camera permission")
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var recordingOverlay: some View {
        VStack {
            HStack {
                // Recording indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: isRecording)
                    
                    Text("REC")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(formatDuration(recordingDuration))
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
        }
    }
    

    
    // MARK: - Bottom Controls Section
    
    private var bottomControlsSection: some View {
        VStack(spacing: 20) {

            
            // Main controls with true center alignment
            ZStack {
                // Record button - absolutely centered
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 5)
                            .frame(width: 67, height: 67)
                        
                        Circle()
                            .fill(isRecording ? Color.red : Color.white)
                            .frame(width: isRecording ? 37 : 52, height: isRecording ? 37 : 52)
                            .animation(.easeInOut(duration: 0.2), value: isRecording)
                        
                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                        }
                    }
                }
                .disabled(!cameraService.isCameraAuthorized)
                
                // Library button - positioned on left side
                HStack {
                    Button(action: {
                        print("📱 Opening video picker")
                        showingVideoPicker = true
                    }) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.leading, 50)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 34)
        .background(Color.clear)
    }
    
    private var processingIndicator: some View {
        Button(action: {
            // Navigate to processing queue
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
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
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
                    
                    Button("Check Permission") {
                        cameraService.checkCameraPermission()
                    }
                }
                
                Section("Processing") {
                    HStack {
                        Text("Videos in Queue")
                        Spacer()
                        Text("\(videoProcessor.processingVideos.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Debug") {
                    HStack {
                        Text("Session Running")
                        Spacer()
                        Text(cameraService.session.isRunning ? "Yes" : "No")
                            .foregroundColor(cameraService.session.isRunning ? .green : .red)
                    }
                    
                    HStack {
                        Text("Session Inputs")
                        Spacer()
                        Text("\(cameraService.session.inputs.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Session Outputs")
                        Spacer()
                        Text("\(cameraService.session.outputs.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Force Restart Session") {
                        print("📱 Force restarting camera session")
                        cameraService.stopSession()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            cameraService.startSession()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Camera Settings")
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
    
    private func setupCamera() {
        print("📱 Setting up camera...")
        
        // Safely check camera permission
        cameraService.checkCameraPermission()
        
        // Force session setup after permission check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.cameraService.isCameraAuthorized && !self.cameraService.session.isRunning {
                print("📱 Camera authorized but session not running - forcing start")
                self.cameraService.startSession()
            }
        }
        
        // Set up recording completion callback
        cameraService.onRecordingCompleted = { videoURL in
            DispatchQueue.main.async {
                print("📱 Recording completed: \(videoURL)")
                handleRecordingCompleted(videoURL: videoURL)
            }
        }
    }
    
    private func toggleRecording() {
        guard cameraService.isCameraAuthorized else {
            print("📱 Cannot record - camera not authorized")
            return
        }
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        print("📱 Starting recording...")
        isRecording = true
        recordingDuration = 0
        
        cameraService.startRecording()
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }
    
    private func stopRecording() {
        print("📱 Stopping recording...")
        isRecording = false
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        cameraService.stopRecording()
    }
    
    private func handleRecordingCompleted(videoURL: URL) {
        print("📱 Handling completed recording: \(videoURL)")
        processVideo(url: videoURL)
    }
    
    private func processVideo(url: URL) {
        print("📱 WorkingCameraView: Processing video: \(url)")
        videoProcessor.processVideo(url: url)
        processingVideoURL = url
        print("📱 WorkingCameraView: Using fullScreenCover to show processing view")
        showingProcessingView = true
    }
    
    private func cleanup() {
        print("📱 Cleaning up camera view")
        recordingTimer?.invalidate()
        recordingTimer = nil
        cameraService.stopSession()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }
}

// MARK: - Preview

struct WorkingCameraView_Previews: PreviewProvider {
    static var previews: some View {
        WorkingCameraView(onNavigateToHome: {})
    }
}
