//
//  CameraRecordView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVFoundation

struct CameraRecordView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var videoProcessor = VideoProcessorService()
    @StateObject private var swingDetector = SwingDetectionService()
    
    @State private var showingVideoPicker = false
    @State private var showingSettings = false
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var showGrid = false
    @State private var navigateToProcessing = false
    @State private var processingVideoURL: URL?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                // Title
                Text("Record Your Swing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                // Camera preview with reduced size and rounded corners
                ZStack {
                    cameraPreviewLayer
                        .aspectRatio(16/9, contentMode: .fit)
                        .scaleEffect(0.85) // Reduce size by 15%
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    // Grid overlay
                    if showGrid {
                        gridOverlay
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .scaleEffect(0.85)
                    }
                    
                    // Golfer positioning overlay
                    golferPositioningOverlay
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .scaleEffect(0.85)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Top overlay controls
            topOverlay
            
            // Bottom overlay controls  
            bottomOverlay
        }
        .ignoresSafeArea(.all)
        .onAppear {
            setupCamera()
            setupSwingDetection()
        }
        .onDisappear {
            cleanup()
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerWithTrimView { url in
                print("📹 CameraRecordView received video URL: \(url)")
                processAndNavigate(to: url)
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsView
        }
        .navigationDestination(isPresented: $navigateToProcessing) {
            VideoProcessingView(videoURL: processingVideoURL ?? URL(string: "file://")!, onNavigateToHome: {
                // Default behavior - just dismiss
            })
                .environmentObject(videoProcessor)
        }
    }
    
    // MARK: - Camera Preview Layer
    
    private var cameraPreviewLayer: some View {
        Group {
            if cameraService.isCameraAuthorized {
                CameraPreview(session: cameraService.session)
                    .onAppear {
                        cameraService.startSession()
                    }
            } else {
                // Permission request view
                cameraPermissionView
            }
        }
    }
    
    private var cameraPermissionView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(25)
            }
        }
    }
    
    // MARK: - Top Overlay
    
    private var topOverlay: some View {
        VStack {
            HStack {
                // Recording indicator
                if isRecording {
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
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                } else {
                    Spacer()
                }
                
                Spacer()
                
                // Camera controls
                HStack(spacing: 16) {
                    // Grid toggle
                    Button(action: {
                        showGrid.toggle()
                    }) {
                        Image(systemName: showGrid ? "grid.circle.fill" : "grid.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    // Camera flip
                    Button(action: cameraService.flipCamera) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Overlay
    
    private var bottomOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 0) {
                // Left side - Library thumbnail
                Button(action: {
                    showingVideoPicker = true
                }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
                
                Spacer()
                
                // Center - Record button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(isRecording ? Color.red : Color.white)
                            .frame(width: isRecording ? 45 : 65, height: isRecording ? 45 : 65)
                            .animation(.easeInOut(duration: 0.2), value: isRecording)
                        
                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .disabled(!cameraService.isCameraAuthorized)
                
                Spacer()
                
                // Right side - Upload video with trim option
                VideoPickerWithTrimButton { url in
                    print("📹 VideoPickerWithTrimButton received video URL: \(url)")
                    processAndNavigate(to: url)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 34)
        }
    }
    
    // MARK: - Grid Overlay
    
    private var gridOverlay: some View {
        Canvas { context, size in
            let path = Path { path in
                // Vertical lines
                let thirdWidth = size.width / 3
                path.move(to: CGPoint(x: thirdWidth, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth, y: size.height))
                path.move(to: CGPoint(x: thirdWidth * 2, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth * 2, y: size.height))
                
                // Horizontal lines
                let thirdHeight = size.height / 3
                path.move(to: CGPoint(x: 0, y: thirdHeight))
                path.addLine(to: CGPoint(x: size.width, y: thirdHeight))
                path.move(to: CGPoint(x: 0, y: thirdHeight * 2))
                path.addLine(to: CGPoint(x: size.width, y: thirdHeight * 2))
            }
            
            context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1)
        }
    }
    
    // MARK: - Golfer Positioning Overlay
    
    private var golferPositioningOverlay: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let golferHeight = size.height * 0.7
            let golferWidth = golferHeight * 0.3
            
            // Body silhouette outline
            let bodyPath = Path { path in
                // Head (circle)
                let headRadius = golferWidth * 0.15
                let headY = centerY - golferHeight * 0.35
                path.addEllipse(in: CGRect(
                    x: centerX - headRadius,
                    y: headY - headRadius,
                    width: headRadius * 2,
                    height: headRadius * 2
                ))
                
                // Torso (rectangle)
                let torsoWidth = golferWidth * 0.6
                let torsoHeight = golferHeight * 0.4
                let torsoY = headY + headRadius
                path.addRoundedRect(in: CGRect(
                    x: centerX - torsoWidth / 2,
                    y: torsoY,
                    width: torsoWidth,
                    height: torsoHeight
                ), cornerSize: CGSize(width: 8, height: 8))
                
                // Arms (slightly bent lines)
                let shoulderY = torsoY + torsoHeight * 0.2
                let armLength = golferWidth * 0.8
                
                // Left arm
                path.move(to: CGPoint(x: centerX - torsoWidth / 2, y: shoulderY))
                path.addLine(to: CGPoint(x: centerX - armLength, y: shoulderY + torsoHeight * 0.3))
                
                // Right arm
                path.move(to: CGPoint(x: centerX + torsoWidth / 2, y: shoulderY))
                path.addLine(to: CGPoint(x: centerX + armLength, y: shoulderY + torsoHeight * 0.3))
                
                // Legs
                let legY = torsoY + torsoHeight
                let legLength = golferHeight * 0.35
                let legSpread = golferWidth * 0.3
                
                // Left leg
                path.move(to: CGPoint(x: centerX - legSpread / 2, y: legY))
                path.addLine(to: CGPoint(x: centerX - legSpread, y: legY + legLength))
                
                // Right leg
                path.move(to: CGPoint(x: centerX + legSpread / 2, y: legY))
                path.addLine(to: CGPoint(x: centerX + legSpread, y: legY + legLength))
            }
            
            // Ball position indicator
            let ballRadius: CGFloat = 8
            let ballX = centerX + golferWidth * 0.4
            let ballY = centerY + golferHeight * 0.25
            
            let ballPath = Path { path in
                path.addEllipse(in: CGRect(
                    x: ballX - ballRadius,
                    y: ballY - ballRadius,
                    width: ballRadius * 2,
                    height: ballRadius * 2
                ))
            }
            
            // Alignment grid (additional lines for positioning)
            let alignmentPath = Path { path in
                // Center vertical line
                path.move(to: CGPoint(x: centerX, y: 0))
                path.addLine(to: CGPoint(x: centerX, y: size.height))
                
                // Stance width guides
                let stanceWidth = golferWidth * 1.2
                path.move(to: CGPoint(x: centerX - stanceWidth / 2, y: centerY + golferHeight * 0.3))
                path.addLine(to: CGPoint(x: centerX - stanceWidth / 2, y: size.height))
                
                path.move(to: CGPoint(x: centerX + stanceWidth / 2, y: centerY + golferHeight * 0.3))
                path.addLine(to: CGPoint(x: centerX + stanceWidth / 2, y: size.height))
                
                // Ball position line
                path.move(to: CGPoint(x: ballX, y: ballY - 20))
                path.addLine(to: CGPoint(x: ballX, y: ballY + 40))
            }
            
            // Draw elements
            context.stroke(bodyPath, with: .color(.white.opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            context.fill(ballPath, with: .color(.orange.opacity(0.8)))
            context.stroke(ballPath, with: .color(.white.opacity(0.8)), lineWidth: 2)
            context.stroke(alignmentPath, with: .color(.white.opacity(0.4)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .overlay(
            // Text guidance
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Stand Here")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .offset(x: -20, y: -40)
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ball Position")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .offset(x: 40, y: -20)
                    Spacer()
                }
                
                Spacer()
            }
        )
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
                    
                    Toggle("Show Grid", isOn: $showGrid)
                }
                
                Section("Recording") {
                    Toggle("Auto-trigger on Swing", isOn: $swingDetector.autoTriggerEnabled)
                    
                    Picker("Sensitivity", selection: $swingDetector.sensitivityLevel) {
                        ForEach(SwingDetectionService.SensitivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("Processing") {
                    HStack {
                        Text("Videos in Queue")
                        Spacer()
                        Text("\(videoProcessor.processingVideos.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !videoProcessor.processingVideos.isEmpty {
                        Button("View Processing Queue") {
                            // Navigate to processing queue
                        }
                    }
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
        cameraService.checkCameraPermission()
        
        // Set up recording completion callback
        cameraService.onRecordingCompleted = { videoURL in
            DispatchQueue.main.async {
                handleRecordingCompleted(videoURL: videoURL)
            }
        }
    }
    
    private func setupSwingDetection() {
        swingDetector.onSwingDetected = {
            DispatchQueue.main.async {
                if isRecording {
                    stopRecording()
                }
            }
        }
    }
    
    private func toggleRecording() {
        print("📹 CameraRecordView: toggleRecording called, isRecording: \(isRecording)")
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        print("📹 CameraRecordView: startRecording called")
        guard cameraService.isCameraAuthorized else { 
            print("❌ CameraRecordView: Camera not authorized")
            return 
        }
        
        isRecording = true
        recordingDuration = 0
        
        print("📹 CameraRecordView: Starting camera recording...")
        // Start camera recording
        cameraService.startRecording()
        
        print("📹 CameraRecordView: Starting swing detection...")
        // Start swing detection
        if swingDetector.autoTriggerEnabled {
            swingDetector.startDetection()
        }
        
        print("📹 CameraRecordView: Starting recording timer...")
        // Start recording timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
        print("📹 CameraRecordView: Recording started successfully")
    }
    
    private func stopRecording() {
        isRecording = false
        
        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Stop camera recording
        cameraService.stopRecording()
        
        // Stop swing detection
        swingDetector.stopDetection()
    }
    
    private func handleRecordingCompleted(videoURL: URL) {
        // Auto-navigate to processing view
        processAndNavigate(to: videoURL)
    }
    
    private func processAndNavigate(to videoURL: URL) {
        print("📹 Processing and navigating to video: \(videoURL)")
        print("📹 Setting processingVideoURL and navigateToProcessing = true")
        processingVideoURL = videoURL
        navigateToProcessing = true
    }
    
    private func cleanup() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        cameraService.stopSession()
        swingDetector.stopDetection()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }
}

// MARK: - Preview

struct CameraRecordView_Previews: PreviewProvider {
    static var previews: some View {
        CameraRecordView()
    }
}
