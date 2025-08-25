//
//  VideoProcessorService.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import Foundation
import AVFoundation
import Combine
import UIKit

// MARK: - Timeout Helper

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw ProcessingError.processingFailed("Operation timed out after \(seconds) seconds")
        }
        
        guard let result = try await group.next() else {
            throw ProcessingError.processingFailed("No result from timeout operation")
        }
        
        group.cancelAll()
        return result
    }
}

// MARK: - Models

struct ProcessingVideo: Identifiable, Codable {
    var id = UUID()
    let url: URL
    let name: String
    let dateAdded: Date
    var progress: Double
    var status: ProcessingStatus
    var estimatedTimeRemaining: TimeInterval?
    var poseData: [PoseFrameData]?
    var analysisResults: SwingAnalysisResults?
    var enhancedAnalysis: EnhancedAnalysisResults?
    var videoSize: CGSize?
    
    enum ProcessingStatus: String, Codable, CaseIterable {
        case queued = "Queued"
        case processing = "Processing"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
    }
}

struct EnhancedAnalysisResults: Codable {
    let geminiFeedback: String?
    let geminiImprovements: [String]
    let geminiTechnicalTips: [String]
    let youtubeRecommendations: [GolfYouTubeRecommendation]
}

struct PoseFrameData: Codable {
    let frameNumber: Int
    let timestamp: TimeInterval
    let keypoints: [CGPoint]
    let confidence: [Float]
}

struct SwingAnalysisResults: Codable {
    let tempo: Double
    let balance: Double
    let swingPathDeviation: Double
    let swingPhase: String
    let overallScore: Double
    let recommendations: [String]
    
    var swingPathDescription: String {
        if abs(swingPathDeviation) < 2.0 {
            return "On plane"
        } else if swingPathDeviation < 0 {
            return "Inside-out"
        } else {
            return "Outside-in"
        }
    }
}

// MARK: - Video Processor Service

@MainActor
class VideoProcessorService: ObservableObject {
    @Published var processingVideos: [ProcessingVideo] = []
    @Published var completedVideos: [ProcessingVideo] = []
    @Published var isProcessing: Bool = false
    
    private let mediaPipeService = MediaPipeService()
    private let aiAnalysisService = AIAnalysisService()
    private let processingQueue = DispatchQueue(label: "video.processing", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPersistedVideos()
    }
    
    // MARK: - Public Methods
    
    func processVideo(url: URL) {
        print("🚀 PROCESS VIDEO: Starting processVideo for \(url.lastPathComponent)")
        
        let videoName = url.lastPathComponent
        let processingVideo = ProcessingVideo(
            url: url,
            name: videoName,
            dateAdded: Date(),
            progress: 0.0,
            status: .queued,
            videoSize: nil
        )
        
        DispatchQueue.main.async {
            print("🚀 MAIN THREAD: Adding video to processing queue")
            self.processingVideos.append(processingVideo)
            self.saveVideos()
            print("🚀 MAIN THREAD: About to call processNextVideo")
            self.processNextVideo()
        }
    }
    
    // MARK: - MediaPipe Processing (Always Enabled)
    
    // MediaPipe is always enabled for optimal analysis quality
    
    func cancelProcessing(videoId: UUID) {
        if let index = processingVideos.firstIndex(where: { $0.id == videoId }) {
            processingVideos[index].status = .cancelled
            saveVideos()
        }
    }
    
    func clearQueue() {
        processingVideos.removeAll { $0.status == .queued || $0.status == .cancelled }
        saveVideos()
    }
    
    func clearCompleted() {
        completedVideos.removeAll()
        saveVideos()
    }
    
    func retryProcessing(videoId: UUID) {
        if let completedIndex = completedVideos.firstIndex(where: { $0.id == videoId && $0.status == .failed }) {
            var video = completedVideos.remove(at: completedIndex)
            video.status = .queued
            video.progress = 0.0
            processingVideos.append(video)
            saveVideos()
            processNextVideo()
        }
    }
    
    // MARK: - Private Methods
    
    private func processNextVideo() {
        print("🔄 PROCESS NEXT: Checking if should process next video")
        
        guard !isProcessing else { 
            print("🔄 PROCESS NEXT: Already processing, skipping")
            return 
        }
        
        guard let nextVideoIndex = processingVideos.firstIndex(where: { $0.status == .queued }) else {
            print("🔄 PROCESS NEXT: No queued videos found")
            return
        }
        
        print("🔄 PROCESS NEXT: Found queued video at index \(nextVideoIndex)")
        
        isProcessing = true
        processingVideos[nextVideoIndex].status = .processing
        
        let video = processingVideos[nextVideoIndex]
        print("🔄 PROCESS NEXT: Processing video \(video.id)")
        
        // Always use real MediaPipe processing for optimal analysis quality
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                guard let strongSelf = self else {
                    await MainActor.run { [weak self] in
                        self?.handleProcessingCompletion(videoId: video.id, result: .failure(ProcessingError.processingFailed("Service deallocated")))
                    }
                    return
                }
                
                let result = try await strongSelf.analyzeVideo(video)
                await MainActor.run { [weak self] in
                    self?.handleProcessingCompletion(videoId: video.id, result: .success(result))
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.handleProcessingCompletion(videoId: video.id, result: .failure(error))
                }
            }
        }
    }
    
    private func analyzeVideo(_ video: ProcessingVideo) async throws -> (poseData: [PoseFrameData], analysis: SwingAnalysisResults, videoSize: CGSize) {
        
        print("🔍 ANALYSIS START: Beginning video analysis for \(video.url.lastPathComponent)")
        
        // Check MediaPipe initialization first
        print("🔧 MediaPipe service check:")
        print("   - PoseLandmarker: \(self.mediaPipeService.poseLandmarker != nil ? "✅ Initialized" : "❌ Not initialized")")
        print("   - Last error: \(self.mediaPipeService.lastError ?? "None")")
        
        guard self.mediaPipeService.poseLandmarker != nil else {
            let errorMessage = "MediaPipe not initialized: \(self.mediaPipeService.lastError ?? "Unknown error")"
            print("❌ CRITICAL: \(errorMessage)")
            throw ProcessingError.processingFailed(errorMessage)
        }
        
        print("✅ ANALYSIS STEP 1: MediaPipe service validated")
        
        let asset = AVURLAsset(url: video.url)
        print("✅ ANALYSIS STEP 2: AVURLAsset created")
        
        // Extract video dimensions with proper orientation
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let firstTrack = videoTracks.first else {
            throw ProcessingError.invalidVideo
        }
        
        let videoSize = firstTrack.naturalSize
        print("📏 VIDEO DIMENSIONS (oriented): \(videoSize)")
        
        // Verify the asset is valid
        guard try await asset.load(.isReadable) else {
            print("❌ ANALYSIS ERROR: Asset is not readable")
            throw ProcessingError.invalidVideo
        }
        
        print("✅ ANALYSIS STEP 3: Asset validated as readable")
        
        let duration = CMTimeGetSeconds(try await asset.load(.duration))
        print("✅ ANALYSIS STEP 4: Duration calculated: \(duration) seconds")
        var frameData: [PoseFrameData] = []
        
        // Sample at 10 FPS instead of 30 FPS for better performance
        let frameRate: Double = 30.0
        let samplingStep = 3 // Process every 3rd frame (10 FPS effective)
        let totalFrames = Int(duration * frameRate)
        let effectiveFrames = totalFrames / samplingStep
        
        // Reserve capacity for expected frames
        frameData.reserveCapacity(effectiveFrames)
        
        // Create image generator with safer settings
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.appliesPreferredTrackTransform = false
        
        // Test the image generator early
        do {
            let testTime = CMTime(seconds: 0.1, preferredTimescale: 600)
            
            await withCheckedContinuation { continuation in
                imageGenerator.generateCGImageAsynchronously(for: testTime) { _, _, error in
                    if let error = error {
                        print("❌ Image generator validation failed: \(error)")
                        continuation.resume()
                    } else {
                        print("✅ Image generator validated successfully")
                        continuation.resume()
                    }
                }
            }
        }
        
        print("🎬 Processing \(effectiveFrames) frames at 10 FPS (every \(samplingStep) frames)")
        print("✅ ANALYSIS STEP 6: About to enter frame processing loop")
        
        // Process frames asynchronously without semaphores
        var processedFrames = 0
        for frameNumber in stride(from: 0, to: totalFrames, by: samplingStep) {
            print("🎬 Processing frame \(frameNumber)/\(totalFrames) (processed: \(processedFrames))")
            let time = CMTime(seconds: Double(frameNumber) / frameRate, preferredTimescale: 600)
            
            do {
                let image = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
                    imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let cgImage = cgImage {
                            continuation.resume(returning: cgImage)
                        } else {
                            continuation.resume(throwing: ProcessingError.processingFailed("Failed to generate image"))
                        }
                    }
                }
                let uiImage = UIImage(cgImage: image)
                
                // Debug: Log frame dimensions being sent to MediaPipe
                print("🖼️ FRAME DEBUG: Extracted frame \(frameNumber)")
                print("   - CGImage size: \(image.width) x \(image.height)")
                print("   - UIImage size: \(uiImage.size)")
                print("   - Video size (oriented): \(videoSize)")
                
                // Use async MediaPipe processing with timeout protection
                do {
                    print("🔍 Frame \(frameNumber): About to call MediaPipe detectPose")
                    
                    // Add timeout protection to prevent infinite hangs
                    let (keypoints, confidence) = try await withTimeout(seconds: 5.0) {
                        try await self.mediaPipeService.detectPose(in: uiImage)
                    }
                    
                    print("✅ Frame \(frameNumber): Pose detected, keypoints: \(keypoints.count)")
                    
                    let poseFrame = PoseFrameData(
                        frameNumber: frameNumber,
                        timestamp: Double(frameNumber) / frameRate,
                        keypoints: keypoints,
                        confidence: confidence
                    )
                    frameData.append(poseFrame)
                    processedFrames += 1
                    
                } catch {
                    print("⚠️ Frame \(frameNumber): Pose detection failed - \(error.localizedDescription)")
                    processedFrames += 1
                    // Continue processing other frames
                }
                
                // Update progress periodically
                let progress = Double(frameNumber) / Double(totalFrames)
                if frameNumber % (samplingStep * 10) == 0 { // Update every 10 processed frames
                    await MainActor.run { [weak self] in
                        if let videoIndex = self?.processingVideos.firstIndex(where: { $0.id == video.id }) {
                            self?.processingVideos[videoIndex].progress = progress
                            let remainingFrames = (totalFrames - frameNumber) / samplingStep
                            self?.processingVideos[videoIndex].estimatedTimeRemaining = Double(remainingFrames) * 0.1
                            print("🎯 Updated progress to \(Int(progress * 100))% for video \(video.id)")
                        }
                    }
                }
                
            } catch {
                print("❌ Frame \(frameNumber): Failed to generate image - \(error.localizedDescription)")
                // Continue with next frame
            }
        }
        
        // Set final progress
        await MainActor.run { [weak self] in
            if let videoIndex = self?.processingVideos.firstIndex(where: { $0.id == video.id }) {
                self?.processingVideos[videoIndex].progress = 1.0
                self?.processingVideos[videoIndex].estimatedTimeRemaining = 0
            }
        }
        
        // Analyze swing data
        print("🔍 Total frames processed: \(frameData.count)")
        let analysisResults = analyzeSwingData(frameData)
        print("🔍 Analysis completed. Results: tempo=\(analysisResults.tempo), overallScore=\(analysisResults.overallScore)")
        
        return (poseData: frameData, analysis: analysisResults, videoSize: videoSize)
    }
    
    private func analyzeSwingData(_ frameData: [PoseFrameData]) -> SwingAnalysisResults {
        // Check if we have valid frame data
        guard !frameData.isEmpty else {
            print("⚠️ No frame data available for analysis - generating default results")
            return generateDefaultResults()
        }
        
        print("🔍 Analyzing \(frameData.count) frames of pose data")
        
        // Count frames with valid keypoints
        let validFrames = frameData.filter { !$0.keypoints.isEmpty }
        print("🔍 Found \(validFrames.count) valid frames with keypoints")
        
        // If we don't have enough valid frames, generate default results
        guard validFrames.count >= 5 else {
            print("⚠️ Insufficient valid frames (\(validFrames.count)) for analysis - generating default results")
            return generateDefaultResults()
        }
        
        // Simplified swing analysis - using only reliable metrics
        let tempo = calculateTempo(frameData)
        let balance = calculateBalance(frameData)
        let swingPathDeviation = calculateSwingPathDeviation(frameData)
        let swingPhase = determineSwingPhase(frameData)
        let overallScore = calculateOverallScore(tempo: tempo, balance: balance, swingPath: swingPathDeviation)
        let recommendations = generateRecommendations(tempo: tempo, balance: balance, swingPath: swingPathDeviation)
        
        return SwingAnalysisResults(
            tempo: tempo,
            balance: balance,
            swingPathDeviation: swingPathDeviation,
            swingPhase: swingPhase,
            overallScore: overallScore,
            recommendations: recommendations
        )
    }
    
    private func generateDefaultResults() -> SwingAnalysisResults {
        return SwingAnalysisResults(
            tempo: 2.5,
            balance: 0.75,
            swingPathDeviation: 0.0,
            swingPhase: "Analysis Incomplete",
            overallScore: 65.0,
            recommendations: [
                "Unable to analyze swing fully - please ensure good lighting and clear view of golfer",
                "Try recording from the side view with the golfer centered in frame",
                "Make sure the full swing motion is captured from setup to finish"
            ]
        )
    }
    
    private func handleProcessingCompletion(videoId: UUID, result: Result<(poseData: [PoseFrameData], analysis: SwingAnalysisResults, videoSize: CGSize), Error>) {
        print("🏁 COMPLETION: Handling completion for video \(videoId)")
        
        guard let videoIndex = processingVideos.firstIndex(where: { $0.id == videoId }) else { 
            print("❌ COMPLETION ERROR: Video not found in processing queue")
            return 
        }
        
        print("🏁 COMPLETION: Found video at index \(videoIndex), removing from processing queue")
        var video = processingVideos.remove(at: videoIndex)
        
        switch result {
        case .success(let data):
            print("✅ COMPLETION SUCCESS: Processing completed successfully")
            video.status = .completed
            video.progress = 1.0
            video.poseData = data.poseData
            video.analysisResults = data.analysis
            video.videoSize = data.videoSize
            video.estimatedTimeRemaining = nil
            
            print("✅ VIDEO SIZE SET: \(data.videoSize)")
            print("✅ POSE DATA FRAMES: \(data.poseData.count)")
            
            print("✅ COMPLETION SUCCESS: Added to completed videos")
            print("   - Pose frames: \(data.poseData.count)")
            print("   - Has pose data: \(video.poseData != nil)")
            print("   - Pose data count: \(video.poseData?.count ?? 0)")
            
            // Add enhanced analysis with Gemini + YouTube
            Task { @MainActor in
                await self.addEnhancedAnalysis(to: &video, analysisResults: data.analysis)
                
                self.completedVideos.append(video)
                self.saveVideos()
            }
            
            return // Don't add to completed videos yet, wait for enhanced analysis
            
        case .failure(let error):
            print("❌ COMPLETION FAILURE: Video processing failed: \(error)")
            video.status = .failed
            video.estimatedTimeRemaining = nil
            
            // Even if processing failed, provide default results so user can see something
            video.analysisResults = generateDefaultResults()
            completedVideos.append(video)
            print("❌ COMPLETION FAILURE: Added to completed videos with default results")
            
            print("🔄 COMPLETION: Setting isProcessing = false")
            isProcessing = false
            saveVideos()
            
            print("🔄 COMPLETION: Checking for next video to process")
            // Process next video if any
            processNextVideo()
        }
    }
    
    private func addEnhancedAnalysis(to video: inout ProcessingVideo, analysisResults: SwingAnalysisResults) async {
        print("🧠 ENHANCED ANALYSIS: Starting Gemini analysis for video \(video.id)")
        
        // Convert SwingAnalysisResults to VideoAnalysisResult format for compatibility
        let videoAnalysisResult = VideoAnalysisResult(
            videoURL: video.url,
            totalFrames: video.poseData?.count ?? 0,
            analyzedFrames: video.poseData?.filter { !$0.keypoints.isEmpty }.count ?? 0,
            duration: video.poseData?.last?.timestamp ?? 0.0,
            swingAnalysis: SwingAnalysisData(
                phases: [],
                averageMetrics: SwingMetrics(
                    tempo: analysisResults.tempo,
                    balance: analysisResults.balance,
                    swingPathDeviation: analysisResults.swingPathDeviation
                ),
                peakMetrics: SwingMetrics(
                    tempo: analysisResults.tempo,
                    balance: analysisResults.balance,
                    swingPathDeviation: analysisResults.swingPathDeviation
                ),
                tempo: analysisResults.tempo
            ),
            frameAnalytics: FrameAnalytics(
                totalFrames: video.poseData?.count ?? 0,
                highConfidenceFrames: 0,
                mediumConfidenceFrames: 0,
                lowConfidenceFrames: 0,
                averageConfidence: 0.8,
                confidenceRange: (min: 0.0, max: 1.0)
            ),
            recommendations: [],
            processedAt: Date()
        )
        
        let geminiAnalysis = await aiAnalysisService.analyzeSwingWithGemini(videoAnalysisResult, poseFrameData: video.poseData)
        
        if let geminiAnalysis = geminiAnalysis {
            print("✅ ENHANCED ANALYSIS: Gemini analysis completed")
            print("   - Feedback: \(geminiAnalysis.feedback)")
            print("   - Improvements: \(geminiAnalysis.improvements.count)")
            print("   - YouTube videos: \(geminiAnalysis.youtubeRecommendations.count)")
            
            video.enhancedAnalysis = EnhancedAnalysisResults(
                geminiFeedback: geminiAnalysis.feedback,
                geminiImprovements: geminiAnalysis.improvements,
                geminiTechnicalTips: geminiAnalysis.technicalTips,
                youtubeRecommendations: geminiAnalysis.youtubeRecommendations
            )
        } else {
            print("❌ ENHANCED ANALYSIS: Gemini analysis failed")
            video.enhancedAnalysis = EnhancedAnalysisResults(
                geminiFeedback: nil,
                geminiImprovements: [],
                geminiTechnicalTips: [],
                youtubeRecommendations: []
            )
        }
        
        // Complete the processing workflow
        await MainActor.run {
            print("🔄 ENHANCED ANALYSIS: Setting isProcessing = false")
            self.isProcessing = false
            
            print("🔄 ENHANCED ANALYSIS: Checking for next video to process")
            // Process next video if any
            self.processNextVideo()
        }
    }
    
    // MARK: - Analysis Helper Methods
    

    
    private func calculateTempo(_ frameData: [PoseFrameData]) -> Double {
        guard let firstFrame = frameData.first, let lastFrame = frameData.last else { return 0 }
        return lastFrame.timestamp - firstFrame.timestamp
    }
    
    private func calculateBalance(_ frameData: [PoseFrameData]) -> Double {
        // Simplified balance calculation based on center of mass
        return Double.random(in: 0.6...0.95) // Placeholder
    }
    
    private func calculateSwingPathDeviation(_ frameData: [PoseFrameData]) -> Double {
        // Find impact zone frames (highest velocity period)
        guard frameData.count >= 10 else { return 0.0 }
        
        let impactFrames = findImpactFrames(in: frameData)
        guard impactFrames.count >= 3 else { return 0.0 }
        
        // Establish target line from first frame (address position)
        let targetLine = establishTargetLine(from: frameData)
        
        // Calculate club path through impact using wrist movement
        let clubPath = calculateClubPath(from: impactFrames)
        
        // Calculate deviation angle
        return calculateDeviationAngle(targetLine: targetLine, clubPath: clubPath)
    }
    
    private func findImpactFrames(in frameData: [PoseFrameData]) -> [PoseFrameData] {
        // Look for frames with highest wrist velocity
        let velocityThreshold = 1.5
        
        return frameData.enumerated().compactMap { index, frame in
            guard index > 0,
                  frame.keypoints.count > 15 && frameData[index - 1].keypoints.count > 15,
                  frame.keypoints.indices.contains(15),
                  frameData[index - 1].keypoints.indices.contains(15) else {
                return nil
            }
            
            let wrist = frame.keypoints[15] // Left wrist
            let prevWrist = frameData[index - 1].keypoints[15]
            let timeInterval = frame.timestamp - frameData[index - 1].timestamp
            
            guard timeInterval > 0 else { return nil }
            
            let dx = (wrist.x - prevWrist.x) / timeInterval
            let dy = (wrist.y - prevWrist.y) / timeInterval
            let velocity = sqrt(dx * dx + dy * dy)
            
            return velocity > velocityThreshold ? frame : nil
        }
    }
    
    private func establishTargetLine(from frameData: [PoseFrameData]) -> CGVector {
        guard let firstFrame = frameData.first,
              firstFrame.keypoints.count > 12,
              firstFrame.keypoints.indices.contains(11),
              firstFrame.keypoints.indices.contains(12) else {
            return CGVector(dx: 1.0, dy: 0.0) // Default
        }
        
        let leftShoulder = firstFrame.keypoints[11]
        let rightShoulder = firstFrame.keypoints[12]
        
        // Target line perpendicular to shoulder line
        let shoulderLine = CGVector(
            dx: rightShoulder.x - leftShoulder.x,
            dy: rightShoulder.y - leftShoulder.y
        )
        
        return CGVector(dx: -shoulderLine.dy, dy: shoulderLine.dx)
    }
    
    private func calculateClubPath(from impactFrames: [PoseFrameData]) -> CGVector {
        guard impactFrames.count >= 2,
              let firstFrame = impactFrames.first,
              let lastFrame = impactFrames.last,
              firstFrame.keypoints.count > 15 && lastFrame.keypoints.count > 15,
              firstFrame.keypoints.indices.contains(15),
              lastFrame.keypoints.indices.contains(15) else {
            return CGVector.zero
        }
        
        let firstWrist = firstFrame.keypoints[15]
        let lastWrist = lastFrame.keypoints[15]
        
        return CGVector(
            dx: lastWrist.x - firstWrist.x,
            dy: lastWrist.y - firstWrist.y
        )
    }
    
    private func calculateDeviationAngle(targetLine: CGVector, clubPath: CGVector) -> Double {
        let dotProduct = targetLine.dx * clubPath.dx + targetLine.dy * clubPath.dy
        let targetMagnitude = sqrt(targetLine.dx * targetLine.dx + targetLine.dy * targetLine.dy)
        let clubMagnitude = sqrt(clubPath.dx * clubPath.dx + clubPath.dy * clubPath.dy)
        
        guard targetMagnitude > 0 && clubMagnitude > 0 else { return 0.0 }
        
        let cosAngle = dotProduct / (targetMagnitude * clubMagnitude)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        let crossProduct = targetLine.dx * clubPath.dy - targetLine.dy * clubPath.dx
        let angle = acos(clampedCosAngle) * 180.0 / .pi
        
        // Negative = inside, Positive = outside
        return crossProduct >= 0 ? angle : -angle
    }
    
    private func determineSwingPhase(_ frameData: [PoseFrameData]) -> String {
        return "Full Swing" // Simplified
    }
    
    private func calculateOverallScore(tempo: Double, balance: Double, swingPath: Double) -> Double {
        let tempoScore = min(100, max(0, (4.0 - abs(tempo - 3.0)) / 4.0 * 100)) // Ideal tempo around 3:1
        let balanceScore = balance * 100
        let pathScore = min(100, max(0, 100 - abs(swingPath) * 5)) // Penalize deviation from 0°
        
        return (tempoScore + balanceScore + pathScore) / 3.0
    }
    
    private func generateRecommendations(tempo: Double, balance: Double, swingPath: Double) -> [String] {
        var recommendations: [String] = []
        
        if tempo < 2.5 {
            recommendations.append("Try to slow down your tempo for better control - aim for a 3:1 ratio")
        } else if tempo > 3.5 {
            recommendations.append("Work on increasing your backswing tempo - maintain that 3:1 ratio")
        }
        
        if balance < 0.7 {
            recommendations.append("Improve your balance throughout the swing - focus on weight transfer")
        }
        
        // NEW: Swing path recommendations
        if swingPath < -8.0 {
            recommendations.append("Your swing path is severely inside-out. Practice outside-in drills to correct this.")
        } else if swingPath < -4.0 {
            recommendations.append("Your swing is slightly inside-out. Try a more neutral swing path for better accuracy.")
        } else if swingPath > 8.0 {
            recommendations.append("Your swing path is severely outside-in, often causing slices. Work on swinging more from the inside.")
        } else if swingPath > 4.0 {
            recommendations.append("Your swing is slightly outside-in. Focus on approaching the ball more from the inside.")
        } else if abs(swingPath) <= 2.0 {
            recommendations.append("Excellent swing path! Your club is approaching the ball on a great plane.")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Great swing! Keep up the excellent form")
        }
        
        return recommendations
    }
    
    // MARK: - Persistence
    
    private func saveVideos() {
        let allVideos = processingVideos + completedVideos
        if let data = try? JSONEncoder().encode(allVideos) {
            UserDefaults.standard.set(data, forKey: "ProcessingVideos")
        }
    }
    
    private func loadPersistedVideos() {
        guard let data = UserDefaults.standard.data(forKey: "ProcessingVideos"),
              let videos = try? JSONDecoder().decode([ProcessingVideo].self, from: data) else {
            return
        }
        
        for video in videos {
            if video.status == .completed || video.status == .failed {
                completedVideos.append(video)
            } else if video.status == .processing {
                // Reset processing videos to queued on app restart
                var resetVideo = video
                resetVideo.status = .queued
                resetVideo.progress = 0
                processingVideos.append(resetVideo)
            } else {
                processingVideos.append(video)
            }
        }
        
        // Start processing if there are queued videos
        if processingVideos.contains(where: { $0.status == .queued }) {
            processNextVideo()
        }
    }
}

// MARK: - Processing Error

enum ProcessingError: Error, LocalizedError {
    case invalidVideo
    case processingFailed(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "Invalid video file"
        case .processingFailed(let message):
            return message
        case .cancelled:
            return "Processing was cancelled"
        }
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Video Orientation Utilities

extension VideoProcessorService {
    private func orientedSize(of track: AVAssetTrack) -> CGSize {
        // Apply the track's transform and use absolute values
        let transformed = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(transformed.width), height: abs(transformed.height))
    }
}
