//
//  VideoProcessingView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVFoundation

struct VideoProcessingView: View {
    let videoURL: URL
    @EnvironmentObject var videoProcessor: VideoProcessorService
    @Environment(\.presentationMode) var presentationMode
    
    // Closure to navigate to home tab
    let onNavigateToHome: () -> Void
    
    @State private var videoId: UUID?
    @State private var videoThumbnail: UIImage?
    @State private var showingResultsSheet = false
    @State private var processingStatusText = "Initializing analysis..."
    @State private var analysisCompleted = false
    @State private var buttonPressed = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var currentAnalysisIndex = 0
    
    private let analysisAspects = [
        "alignment",
        "footwork", 
        "backswing",
        "tempo",
        "downswing",
        "posture",
        "impact"
    ]
    
    private let statusMessages = [
        "Loading video...",
        "Detecting poses...", 
        "Analyzing swing motion...",
        "Calculating metrics...",
        "Generating insights...",
        "Finalizing results..."
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 20) {
                // Navigation & Title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Processing Video")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("AI Swing Analysis")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Cancel button (only show if not completed)
                    if !analysisCompleted {
                        Button(action: cancelProcessing) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    } else {
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
            
            Spacer()
            
            // Main Content - Centered
            VStack(spacing: 32) {
                // Video thumbnail
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 280, height: 200)
                    .overlay(
                        Group {
                            if let thumbnail = videoThumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 280, height: 200)
                                    .cornerRadius(20)
                            } else {
                                Image(systemName: "video")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                
                // Processing indicator with golf ball
                VStack(spacing: 16) {
                    // Spinning golf ball
                    Image("golfer-figurine")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(360))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: true)
                }
                .frame(height: 100)
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Spacer().frame(height: 100)
        }
        .background(Color.white)
        .ignoresSafeArea(.container, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            setupProcessing()
            generateThumbnail()
            startAnalysisRotation()
        }
        .onChange(of: showingResultsSheet) { newValue in
            print("🚀 SHEET STATE CHANGED - showingResultsSheet: \(newValue)")
        }
        .alert("Processing Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showingResultsSheet) {
            if let video = currentVideo, video.analysisResults != nil {
                RedesignedSwingResultsView(video: video)
                    .onAppear {
                        print("🚀 REDESIGNED RESULTS VIEW APPEARED - New template structure loaded")
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Results Not Available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(errorMessage.isEmpty ? "Analysis data is not ready yet" : errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button("Close") {
                        showingResultsSheet = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .onAppear {
                    print("🚀 SHEET ERROR - No video data or analysis results available")
                }
            }
        }
    }
    
    // MARK: - Processing Header Section
    
    private var processingHeaderSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("VIDEO PROCESSING")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(spacing: 30) {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Processing Video")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("AI Swing Analysis")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.blue.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Video Analysis Section
    
    private var videoAnalysisSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("ANALYZING SWING")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(spacing: 40) {
                // Title
                Text("AI Analysis in Progress")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // Video thumbnail with processing overlay
                ZStack {
                    // Background circle for emphasis
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.03), Color.purple.opacity(0.01)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 320, height: 320)
                    
                    // Video thumbnail
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 280, height: 280 * 9/16) // 16:9 aspect ratio
                        .overlay(
                            Group {
                                if let thumbnail = videoThumbnail {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 280, height: 280 * 9/16)
                                        .cornerRadius(16)
                                } else {
                                    Image(systemName: "video")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                }
                            }
                        )
                        .overlay(
                            // Processing overlay
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 280, height: 280 * 9/16)
                        )
                    
                    // Processing animation
                    VStack(spacing: 16) {
                        // Animated processing indicator
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .rotationEffect(.degrees(currentVideo?.progress ?? 0 > 0 ? 360 : 0))
                                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: currentVideo?.progress ?? 0 > 0)
                        }
                        
                        Text("Analyzing \(analysisAspects[currentAnalysisIndex])")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let progress = currentVideo?.progress {
                            Text("\(Int(progress * 100))% Complete")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(height: 280)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.purple.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentVideo: ProcessingVideo? {
        guard let videoId = videoId else { return nil }
        
        // First check processing videos
        if let video = videoProcessor.processingVideos.first(where: { $0.id == videoId }) {
            return video
        }
        
        // Then check completed videos
        return videoProcessor.completedVideos.first(where: { $0.id == videoId })
    }
    
    // MARK: - Progress Detail Section
    
    private var progressDetailSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("PROGRESS TRACKING")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.green.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(spacing: 25) {
                Text("Processing Status")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                // Progress cards
                VStack(spacing: 16) {
                    if let video = currentVideo {
                        // Progress bar card
                        VStack(spacing: 16) {
                            HStack {
                                Text("Progress")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                
                                Spacer()
                                
                                Text("\(Int(video.progress * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.black)
                            }
                            
                            ProgressView(value: video.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(y: 2)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        )
                        
                        // Time remaining card
                        if let timeRemaining = video.estimatedTimeRemaining {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                
                                Text("~\(Int(timeRemaining / 60)):\(String(format: "%02d", Int(timeRemaining) % 60)) remaining")
                                    .font(.body)
                                    .foregroundColor(.black)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            )
                        }
                    }
                    
                    // Status text card
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                        
                        Text(processingStatusText)
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.green.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Analysis Insights Section
    
    private var analysisInsightsSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("ANALYSIS INSIGHTS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(spacing: 25) {
                Text("What we're analyzing")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                // Analysis points
                VStack(spacing: 16) {
                    let analysisPoints = [
                        ("golf.tee", "Swing path and club trajectory"),
                        ("figure.stand", "Body posture and balance"),
                        ("timer", "Tempo and timing"),
                        ("target", "Key position checkpoints")
                    ]
                    
                    ForEach(analysisPoints, id: \.0) { iconName, description in
                        HStack(spacing: 16) {
                            Image(systemName: iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        )
                    }
                }
                
                // Cancel button (only show if not completed)
                if !analysisCompleted {
                    Button(action: cancelProcessing) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .font(.title3)
                            
                            Text("Cancel Processing")
                                .font(.headline)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.orange.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - View Results Button
    
    private var viewResultsButton: some View {
        Button(action: {
            print("🚀 BUTTON PRESSED - Manual navigation to results triggered")
            
            guard let video = currentVideo else {
                print("❌ No current video available")
                errorMessage = "Video data not found"
                showingError = true
                return
            }
            
            guard video.analysisResults != nil else {
                print("❌ No analysis results available")
                errorMessage = "Analysis results not available"
                showingError = true
                return
            }
            
            print("✅ Video found with analysis results - showing results")
            
            // Provide visual feedback immediately
            buttonPressed = true
            
            // Use sheet as the only navigation method
            showingResultsSheet = true
            
            // Reset visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                buttonPressed = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("View Analysis Results")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(buttonPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    
    private func setupProcessing() {
        print("🎬 Setting up video processing for URL: \(videoURL)")
        
        // Start processing the video
        videoProcessor.processVideo(url: videoURL)
        print("📤 Video sent to processor")
        
        // Find the processing video
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("📋 Looking for processing video in queue...")
            if let video = videoProcessor.processingVideos.last {
                print("✅ Found processing video: \(video.id)")
                videoId = video.id
                startStatusUpdates()
                monitorProcessingCompletion()
            } else {
                print("❌ No processing video found in queue")
                print("📊 Processing videos count: \(videoProcessor.processingVideos.count)")
                errorMessage = "Failed to start video processing"
                showingError = true
            }
        }
    }
    
    private func startStatusUpdates() {
        // Update status text based on progress
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard let video = currentVideo else {
                timer.invalidate()
                return
            }
            
            if video.status == .completed {
                timer.invalidate()
                return
            }
            
            let progressIndex = min(Int(video.progress * Double(statusMessages.count)), statusMessages.count - 1)
            processingStatusText = statusMessages[progressIndex]
        }
    }
    
    private func monitorProcessingCompletion() {
        print("🔄 MONITOR: Starting completion monitoring")
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            print("⏰ MONITOR: Timer tick - checking completion status (on main thread: \(Thread.isMainThread))")
            
            guard let currentVideoId = videoId else {
                print("⚠️ No video ID available")
                timer.invalidate()
                return
            }
            
            print("🎬 Checking video ID: \(currentVideoId)")
            
            Task { @MainActor in
                print("📊 Processing videos count: \(videoProcessor.processingVideos.count)")
                print("✅ Completed videos count: \(videoProcessor.completedVideos.count)")
            }
            
            Task { @MainActor in
                if let updatedVideo = videoProcessor.processingVideos.first(where: { $0.id == currentVideoId }) {
                print("🔄 Found video in processing queue - progress: \(updatedVideo.progress), status: \(updatedVideo.status)")
                // Video is still processing, continue monitoring
            } else if let completedVideo = videoProcessor.completedVideos.first(where: { $0.id == currentVideoId }) {
                print("✅ Found video in completed queue - status: \(completedVideo.status)")
                print("📊 Has analysis results: \(completedVideo.analysisResults != nil)")
                
                timer.invalidate()
                
                if completedVideo.status == .completed && completedVideo.analysisResults != nil {
                    print("🎉 MONITOR: Video completed successfully with analysis results!")
                    processingStatusText = "Analysis complete!"
                    analysisCompleted = true
                    
                    // Auto-navigate to results immediately
                    print("🚀 MONITOR: Auto-navigating to results... (on main thread: \(Thread.isMainThread))")
                    showingResultsSheet = true
                    
                } else if completedVideo.status == .failed || completedVideo.analysisResults == nil {
                    print("❌ Video processing failed or no analysis results")
                    processingStatusText = "Analysis failed"
                    analysisCompleted = true
                    errorMessage = "Video analysis could not be completed. Please try recording again with better lighting and positioning."
                    
                } else {
                    print("🔄 Video in completed queue but status is: \(completedVideo.status)")
                    processingStatusText = "Processing completed"
                    analysisCompleted = true
                }
                } else {
                    print("⚠️ Video not found in either processing or completed queues")
                    // Log debug info
                    print("📝 All processing videos:")
                    for video in videoProcessor.processingVideos {
                        print("  - ID: \(video.id), Status: \(video.status), Progress: \(video.progress)")
                    }
                    print("📝 All completed videos:")
                    for video in videoProcessor.completedVideos {
                        print("  - ID: \(video.id), Status: \(video.status)")
                    }
                }
            }
        }
    }
    
    private func generateThumbnail() {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.videoThumbnail = UIImage(cgImage: image)
                }
            }
        }
    }
    
    private func startAnalysisRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard !analysisCompleted else {
                timer.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                currentAnalysisIndex = (currentAnalysisIndex + 1) % analysisAspects.count
            }
        }
    }
    
    private func cancelProcessing() {
        if let currentVideoId = videoId {
            videoProcessor.cancelProcessing(videoId: currentVideoId)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

struct VideoProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        VideoProcessingView(videoURL: URL(string: "file://test.mp4")!, onNavigateToHome: {})
            .environmentObject(VideoProcessorService())
    }
}
