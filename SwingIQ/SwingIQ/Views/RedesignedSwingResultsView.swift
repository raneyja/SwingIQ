//
//  RedesignedSwingResultsView.swift
//  SwingIQ
//
//  Created by Amp on 8/19/25.
//

import SwiftUI
import AVKit

struct RedesignedSwingResultsView: View {
    let video: ProcessingVideo
    @Environment(\.presentationMode) var presentationMode
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1.0
    @State private var playbackSpeed: Float = 1.0
    
    // UI State
    @State private var showingSummaryPopup = false
    @State private var hasScrolledToOverview = false
    @State private var videoHasFinished = false
    @State private var shouldTriggerAutoscroll = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            // Full-screen video player
            GeometryReader { geo in
                ZStack {
                    if let player = player {
                        VideoPlayer(player: player)
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .ignoresSafeArea()
                            .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                                isPlaying = (status == .playing)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
                                videoHasFinished = true
                                handleVideoCompletion()
                            }
                    }
                    
                    // MediaPipe skeleton overlay - always visible
                    if let poseData = video.poseData {
                        MediaPipeOverlay(
                            poseData: poseData,
                            currentTime: currentTime,
                            viewSize: geo.size,
                            videoSize: video.videoSize
                        )
                        .allowsHitTesting(false)
                    }
                    
                    // Simple video controls overlay
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Timeline slider
                            Slider(value: $currentTime, in: 0...max(1.0, duration.isFinite ? duration : 1.0)) { editing in
                                if !editing {
                                    seekToTime(currentTime)
                                }
                            }
                            .accentColor(Color(hex: "00B04F"))
                            .padding(.horizontal, 20)
                            
                            // Centered play button with side controls
                            ZStack {
                                HStack {
                                    Spacer()
                                    
                                    Button(action: cyclePlaybackSpeed) {
                                        Text("\(playbackSpeed == 1.0 ? "1x" : String(format: "%.2gx", playbackSpeed))")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Centered play button
                                Button(action: togglePlayback) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            
            // Scrolling results content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to push content below video
                        Spacer()
                            .frame(height: UIScreen.main.bounds.height)
                        
                        // Header with back button
                        headerSection
                        
                        // Results overview (template structure)
                        resultsOverviewSection
                            .id("overview")
                    }
                }
                .onAppear {
                    setupPlayer()
                }
                .onChange(of: shouldTriggerAutoscroll) { shouldScroll in
                    if shouldScroll && !hasScrolledToOverview {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            proxy.scrollTo("overview", anchor: .top)
                        }
                        hasScrolledToOverview = true
                    }
                }
            }
            
            // Summary popup overlay
            if showingSummaryPopup {
                summaryPopupOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            player?.pause()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Swing Analysis")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Video Player Section
    
    private var videoPlayerSection: some View {
        VStack(spacing: 0) {
            // Video player with skeleton overlay
            ZStack {
                if let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                            isPlaying = (status == .playing)
                        }
                }
                
                // MediaPipe skeleton overlay - always visible
                GeometryReader { geometry in
                    if let poseData = video.poseData {
                        MediaPipeOverlay(
                            poseData: poseData,
                            currentTime: currentTime,
                            viewSize: geometry.size,
                            videoSize: video.videoSize
                        )
                    }
                }
            }
            
            // Simple video controls
            HStack(spacing: 20) {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Slider(value: $currentTime, in: 0...max(1.0, duration.isFinite ? duration : 1.0)) { editing in
                    if !editing {
                        seekToTime(currentTime)
                    }
                }
                .accentColor(Color(hex: "00B04F"))
                
                Button(action: cyclePlaybackSpeed) {
                    Text("\(playbackSpeed == 1.0 ? "1x" : String(format: "%.2gx", playbackSpeed))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.6))
        }
    }
    
    // MARK: - Results Overview Section (Template Structure)
    
    private var resultsOverviewSection: some View {
        VStack(spacing: 24) {
            // Overall Assessment
            overallAssessmentSection
            
            // Key Metrics & Data Points
            keyMetricsSection
            
            // Swing Mechanics Breakdown
            swingMechanicsSection
            
            // Recommended Training Videos
            recommendedVideosSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.white)
    }
    
    // MARK: - Overall Assessment
    
    private var overallAssessmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Assessment")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            if let results = video.analysisResults {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text("\(safeInt(results.overallScore))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(scoreColor(results.overallScore))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getScoreLabel(results.overallScore))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(scoreColor(results.overallScore))
                            
                            Text("Overall Score")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    
                    Text(generateOverallAssessment(results))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                        .lineSpacing(4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "F7F8FA"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Key Metrics & Data Points
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics & Data Points")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            if let results = video.analysisResults {
                VStack(spacing: 12) {
                    metricsTableRow(
                        metric: "Swing Tempo",
                        value: "\(String(format: "%.1f", results.tempo))",
                        unit: "bpm",
                        ideal: "70-90 bpm",
                        status: getTempoStatus(results.tempo)
                    )
                    
                    metricsTableRow(
                        metric: "Swing Path",
                        value: "\(abs(safeInt(results.swingPathDeviation)))",
                        unit: "° \(results.swingPathDeviation < 0 ? "inside" : "outside")",
                        ideal: "0-2°",
                        status: getSwingPathStatus(results.swingPathDeviation)
                    )
                    
                    metricsTableRow(
                        metric: "Balance",
                        value: "\(String(format: "%.1f", results.balance * 100))",
                        unit: "%",
                        ideal: "85-95%",
                        status: getBalanceStatus(results.balance)
                    )
                    
                    metricsTableRow(
                        metric: "Swing Phase",
                        value: results.swingPhase,
                        unit: "",
                        ideal: "Complete",
                        status: results.swingPhase.lowercased().contains("complete") ? .excellent : .good
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "F7F8FA"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Swing Mechanics Breakdown
    
    private var swingMechanicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Swing Mechanics Breakdown")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            if let results = video.analysisResults {
                VStack(spacing: 16) {
                    swingPhaseCard(
                        phase: "Address & Setup",
                        timestamp: "0:00",
                        analysis: generateAddressAnalysis(results),
                        status: .good
                    )
                    
                    swingPhaseCard(
                        phase: "Backswing",
                        timestamp: "0:01-0:02",
                        analysis: generateBackswingAnalysis(results),
                        status: getTempoStatus(results.tempo)
                    )
                    
                    swingPhaseCard(
                        phase: "Downswing & Impact",
                        timestamp: "0:02-0:03",
                        analysis: generateDownswingAnalysis(results),
                        status: getSwingPathStatus(results.swingPathDeviation)
                    )
                    
                    swingPhaseCard(
                        phase: "Follow-through",
                        timestamp: "0:03-0:04",
                        analysis: generateFollowThroughAnalysis(results),
                        status: .good
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "F7F8FA"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Recommended Training Videos
    
    private var recommendedVideosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Training Videos")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            if let results = video.analysisResults {
                LazyVStack(spacing: 12) {
                    ForEach(generateRecommendedVideos(results), id: \.title) { video in
                        recommendedVideoCard(video)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "F7F8FA"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Summary Popup Overlay
    
    private var summaryPopupOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "00B04F"))
                
                Text("Analysis Complete")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if let results = video.analysisResults {
                    Text(generateSummary(results))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 20)
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Auto-dismiss after 3.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showingSummaryPopup = false
                    
                    // Trigger autoscroll 1.5 seconds after summary dismisses
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        triggerAutoscroll()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func metricsTableRow(metric: String, value: String, unit: String, ideal: String, status: ResultsMetricStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                Text("Ideal: \(ideal)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(value) \(unit)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(status.color)
                
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func swingPhaseCard(phase: String, timestamp: String, analysis: String, status: ResultsMetricStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("@ \(timestamp)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                Circle()
                    .fill(status.color)
                    .frame(width: 12, height: 12)
            }
            
            Text(analysis)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func recommendedVideoCard(_ videoRec: RecommendedVideo) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: videoRec.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(videoRec.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(videoRec.channel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                
                Text(videoRec.duration)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(Color(hex: "00B04F"))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture {
            // Open YouTube video
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        player = AVPlayer(url: video.url)
        
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            let timeSeconds = time.seconds
            currentTime = timeSeconds.isFinite ? timeSeconds : 0
        }
        
        if let duration = player?.currentItem?.duration {
            let durationSeconds = duration.seconds
            self.duration = durationSeconds.isFinite && durationSeconds > 0 ? durationSeconds : 1.0
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.rate = playbackSpeed
            player?.play()
        }
    }
    
    private func seekToTime(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func cyclePlaybackSpeed() {
        let speeds: [Float] = [0.25, 0.5, 1.0, 2.0]
        if let currentIndex = speeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % speeds.count
            playbackSpeed = speeds[nextIndex]
            if isPlaying {
                player?.rate = playbackSpeed
            }
        }
    }
    
    private func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(value)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 85...100: return Color(hex: "1B8B3A")
        case 70..<85: return Color(hex: "FF6B35")
        case 50..<70: return Color(hex: "8E44AD")
        default: return Color.red
        }
    }
    
    private func getScoreLabel(_ score: Double) -> String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Needs Work"
        }
    }
}

// MARK: - Supporting Types and Extensions

enum ResultsMetricStatus {
    case excellent, good, fair, needsWork
    
    var color: Color {
        switch self {
        case .excellent: return Color(hex: "1B8B3A")
        case .good: return Color(hex: "4A90E2")
        case .fair: return Color(hex: "FF6B35")
        case .needsWork: return Color.red
        }
    }
}

struct RecommendedVideo {
    let title: String
    let channel: String
    let duration: String
    let thumbnailURL: String
    let youtubeURL: String
    let relevantIssue: String
}

// MARK: - Analysis Generation Methods

extension RedesignedSwingResultsView {
    private func generateSummary(_ results: SwingAnalysisResults) -> String {
        let scoreLabel = getScoreLabel(results.overallScore).lowercased()
        let mainIssue = identifyMainIssue(results)
        return "Your swing shows \(scoreLabel) fundamentals with \(mainIssue) being the primary area for improvement."
    }
    
    private func generateOverallAssessment(_ results: SwingAnalysisResults) -> String {
        let strengths = identifyStrengths(results)
        let weaknesses = identifyWeaknesses(results)
        return "Your swing demonstrates \(strengths.joined(separator: " and ")) while showing opportunities to improve \(weaknesses.joined(separator: " and ")). Focus on the recommended areas below to elevate your game to the next level."
    }
    
    private func identifyMainIssue(_ results: SwingAnalysisResults) -> String {
        if abs(results.swingPathDeviation) > 5.0 {
            return "swing path consistency"
        } else if results.tempo < 70 || results.tempo > 90 {
            return "tempo rhythm"
        } else if results.balance < 0.7 {
            return "balance and stability"
        } else {
            return "overall timing"
        }
    }
    
    private func identifyStrengths(_ results: SwingAnalysisResults) -> [String] {
        var strengths: [String] = []
        
        if abs(results.swingPathDeviation) < 3.0 {
            strengths.append("consistent swing path")
        }
        if results.tempo >= 75 && results.tempo <= 85 {
            strengths.append("good tempo rhythm")
        }
        if results.balance >= 0.8 {
            strengths.append("solid balance")
        }
        if results.overallScore >= 80 {
            strengths.append("strong fundamentals")
        }
        
        return strengths.isEmpty ? ["good foundational mechanics"] : strengths
    }
    
    private func identifyWeaknesses(_ results: SwingAnalysisResults) -> [String] {
        var weaknesses: [String] = []
        
        if abs(results.swingPathDeviation) > 5.0 {
            weaknesses.append("swing path consistency")
        }
        if results.tempo < 70 || results.tempo > 90 {
            weaknesses.append("tempo control")
        }
        if results.balance < 0.7 {
            weaknesses.append("balance and stability")
        }
        if results.overallScore < 70 {
            weaknesses.append("general mechanics")
        }
        
        return weaknesses.isEmpty ? ["minor timing adjustments"] : weaknesses
    }
    
    private func generateAddressAnalysis(_ results: SwingAnalysisResults) -> String {
        return "Setup position shows balanced posture with proper alignment. Your stance provides a solid foundation for the swing sequence."
    }
    
    private func generateBackswingAnalysis(_ results: SwingAnalysisResults) -> String {
        if results.tempo >= 75 && results.tempo <= 85 {
            return "Good tempo creates proper coil in the backswing. \(results.balance >= 0.8 ? "Balance remains solid" : "Work on maintaining balance") throughout the takeaway phase."
        } else {
            return "Tempo could be more controlled for better consistency. \(results.tempo < 75 ? "Try slowing down" : "Increase rhythm") for optimal backswing sequence."
        }
    }
    
    private func generateDownswingAnalysis(_ results: SwingAnalysisResults) -> String {
        let pathDescription = abs(results.swingPathDeviation) < 3.0 ? "stays on plane well" : "shows some path deviation (\(results.swingPathDeviation < 0 ? "inside-out" : "outside-in"))"
        return "Downswing sequence shows good initiation. Club \(pathDescription) through impact, with \(results.balance > 0.8 ? "solid" : "variable") balance throughout the motion."
    }
    
    private func generateFollowThroughAnalysis(_ results: SwingAnalysisResults) -> String {
        return "Follow-through shows good extension and balance. Complete finish position indicates proper weight transfer through the swing."
    }
    
    private func getTempoStatus(_ tempo: Double) -> ResultsMetricStatus {
        if tempo >= 75 && tempo <= 85 { return .excellent }
        if tempo >= 70 && tempo <= 90 { return .good }
        if tempo >= 65 && tempo <= 95 { return .fair }
        return .needsWork
    }
    
    private func getBalanceStatus(_ balance: Double) -> ResultsMetricStatus {
        if balance >= 0.85 { return .excellent }
        if balance >= 0.75 { return .good }
        if balance >= 0.65 { return .fair }
        return .needsWork
    }
    
    private func getSwingPathStatus(_ deviation: Double) -> ResultsMetricStatus {
        if abs(deviation) < 2.0 { return .excellent }
        if abs(deviation) < 4.0 { return .good }
        if abs(deviation) < 6.0 { return .fair }
        return .needsWork
    }
    

    
    private func generateRecommendedVideos(_ results: SwingAnalysisResults) -> [RecommendedVideo] {
        var videos: [RecommendedVideo] = []
        
        if abs(results.swingPathDeviation) > 4.0 {
            videos.append(RecommendedVideo(
                title: "Fix Your Swing Path - Inside Out vs Outside In",
                channel: "Golf Instruction Network",
                duration: "8:42",
                thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
                youtubeURL: "https://youtube.com/watch?v=dQw4w9WgXcQ",
                relevantIssue: "Swing Path Deviation"
            ))
        }
        
        if results.tempo < 70 || results.tempo > 90 {
            videos.append(RecommendedVideo(
                title: "Perfect Golf Swing Tempo - 3:1 Ratio Drill",
                channel: "Pro Golf Academy",
                duration: "6:15",
                thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
                youtubeURL: "https://youtube.com/watch?v=dQw4w9WgXcQ",
                relevantIssue: "Tempo Control"
            ))
        }
        
        if results.balance < 0.7 {
            videos.append(RecommendedVideo(
                title: "Balance and Stability Drills",
                channel: "Golf Fitness Expert",
                duration: "12:30",
                thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
                youtubeURL: "https://youtube.com/watch?v=dQw4w9WgXcQ",
                relevantIssue: "Balance & Stability"
            ))
        }
        
        // Always include a general improvement video
        videos.append(RecommendedVideo(
            title: "5-Minute Daily Swing Practice Routine",
            channel: "Golf Daily",
            duration: "5:03",
            thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            youtubeURL: "https://youtube.com/watch?v=dQw4w9WgXcQ",
            relevantIssue: "General Improvement"
        ))
        
        return videos
    }
    
    private func handleVideoCompletion() {
        // Show summary popup when video finishes
        withAnimation(.easeIn(duration: 0.5)) {
            showingSummaryPopup = true
        }
    }
    
    private func triggerAutoscroll() {
        shouldTriggerAutoscroll = true
    }
}
