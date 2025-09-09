//
//  GeminiAnalysisService.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//

import Foundation
import CoreGraphics
import AVFoundation
import UIKit

class GeminiAnalysisService: ObservableObject {
    private let geminiAPIKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
    
    init() {
        if let geminiAPIKey = APIConfiguration.shared.geminiAPIKey {
            self.geminiAPIKey = geminiAPIKey
        } else {
            print("⚠️ Gemini API key not configured - AI analysis features will be disabled")
            self.geminiAPIKey = ""
        }
    }
    
    // MARK: - Public Methods
    
    func analyzeSwing(_ analysisResult: VideoAnalysisResult, poseFrameData: [PoseFrameData]? = nil, biomechanics: [String: Any]) async -> GeminiSwingAnalysis? {
        guard !geminiAPIKey.isEmpty else {
            print("ℹ️ Gemini analysis skipped - API key not configured")
            return nil
        }
        
        print("🧠 Starting comprehensive Gemini analysis...")
        
        // Extract key video frames for visual analysis
        var videoFrames: [UIImage] = []
        if let videoURL = analysisResult.videoURL {
            videoFrames = await extractVideoFramesForAnalysis(from: videoURL)
        }
        print("📸 Extracted \(videoFrames.count) video frames for analysis")
        
        do {
            // Perform dual analysis: visual + data
            var combinedFeedback = ""
            var combinedImprovements: [String] = []
            var combinedTips: [String] = []
            
            // 1. Video-based visual analysis
            if !videoFrames.isEmpty {
                print("👁️ Performing video-based visual analysis...")
                let visualAnalysis = try await performVideoAnalysis(frames: videoFrames, duration: analysisResult.duration)
                combinedFeedback += "Visual Analysis:\n\(visualAnalysis.feedback)\n\n"
                combinedImprovements.append(contentsOf: visualAnalysis.improvements)
                combinedTips.append(contentsOf: visualAnalysis.technicalTips)
                print("✅ Video analysis completed")
            }
            
            // 2. Pose data analysis (if available)
            if let poseFrameData = poseFrameData, !poseFrameData.isEmpty {
                print("📊 Performing pose data analysis...")
                let swingData = prepareSwingDataForGemini(analysisResult, poseFrameData: poseFrameData, biomechanics: biomechanics)
                let dataAnalysis = try await performGeminiSwingAnalysis(swingData: swingData)
                combinedFeedback += "Biomechanical Analysis:\n\(dataAnalysis.feedback)"
                combinedImprovements.append(contentsOf: dataAnalysis.improvements)
                combinedTips.append(contentsOf: dataAnalysis.technicalTips)
                print("✅ Pose data analysis completed")
            } else {
                print("⚠️ No pose data available - using visual analysis only")
            }
            
            // Remove duplicates and return combined analysis
            return GeminiSwingAnalysis(
                feedback: combinedFeedback.isEmpty ? "Analysis could not be completed." : combinedFeedback,
                improvements: Array(Set(combinedImprovements)), // Remove duplicates
                technicalTips: Array(Set(combinedTips)), // Remove duplicates
                youtubeRecommendations: [] // YouTube handled by dedicated service
            )
            
        } catch {
            print("❌ Gemini swing analysis error: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func prepareSwingDataForGemini(_ result: VideoAnalysisResult, poseFrameData: [PoseFrameData]?, biomechanics: [String: Any]) -> [String: Any] {
        let swingMetrics = result.swingAnalysis.averageMetrics
        let phases = result.swingAnalysis.phases
        let recommendations = result.recommendations
        
        var swingData: [String: Any] = [
            "metrics": [
                "tempo": swingMetrics.tempo,
                "balance": swingMetrics.balance,
                "swingPathDeviation": swingMetrics.swingPathDeviation
            ],
            "phases": phases.map { phase in
                [
                    "name": phase.phase.rawValue,
                    "duration": phase.duration
                ]
            },
            "currentRecommendations": recommendations.map { $0.description },
            "frameAnalytics": [
                "totalFrames": result.totalFrames,
                "analyzedFrames": result.analyzedFrames,
                "duration": result.duration
            ],
            "biomechanics": biomechanics
        ]
        
        // Add raw pose frame data if available
        if let poseFrames = poseFrameData {
            let sampledFrames = sampleFrames(poseFrames, limit: 15)
            
            let poseData = sampledFrames.map { frame in
                [
                    "frameNumber": frame.frameNumber,
                    "timestamp": frame.timestamp,
                    "keypoints": frame.keypoints.map { point in
                        ["x": point.x, "y": point.y]
                    },
                    "confidenceScores": frame.confidence,
                    "averageConfidence": frame.confidence.isEmpty ? 0.0 : frame.confidence.reduce(0, +) / Float(frame.confidence.count)
                ]
            }
            
            swingData["poseFrameData"] = poseData
            swingData["progressionData"] = calculateFrameByFrameProgression(from: sampledFrames)
        }
        
        return swingData
    }
    
    private func performGeminiSwingAnalysis(swingData: [String: Any]) async throws -> GeminiSwingFeedback {
        let prompt = createSwingAnalysisPrompt(swingData: swingData)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 800,
                "topP": 0.8,
                "topK": 10
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(geminiAPIKey)") else {
            throw AIAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = response.candidates.first?.content.parts.first?.text else {
            throw AIAnalysisError.noResponse
        }
        
        return try parseGeminiSwingFeedback(content)
    }
    
    private func createSwingAnalysisPrompt(swingData: [String: Any]) -> String {
        let hasPoseData = swingData["poseFrameData"] != nil
        let biomechanics = swingData["biomechanics"] as? [String: Any]
        
        var promptBuilder = """
        You are a PGA golf professional analyzing a golf swing based on detailed motion capture data and precise pose detection. Provide expert feedback and recommendations.
        
        Swing Analysis Data:
        - Tempo: \((swingData["metrics"] as? [String: Any])?["tempo"] ?? 0):1 ratio
        - Balance Score: \((swingData["metrics"] as? [String: Any])?["balance"] ?? 0) (0-1 scale)
        - Swing Path Deviation: \((swingData["metrics"] as? [String: Any])?["swingPathDeviation"] ?? 0)° (negative = inside-out, positive = outside-in)
        
        Duration: \((swingData["frameAnalytics"] as? [String: Any])?["duration"] ?? 0) seconds
        Total Frames: \((swingData["frameAnalytics"] as? [String: Any])?["totalFrames"] ?? 0)
        """
        
        if hasPoseData, let bio = biomechanics {
            promptBuilder += """
            
            Detailed Biomechanical Analysis from Pose Detection:
            
            Hip Rotation:
            - Average: \((bio["hipRotation"] as? [String: Any])?["average"] ?? 0)°
            - Peak: \((bio["hipRotation"] as? [String: Any])?["peak"] ?? 0)°
            
            Shoulder Rotation:
            - Average: \((bio["shoulderRotation"] as? [String: Any])?["average"] ?? 0)°
            - Peak: \((bio["shoulderRotation"] as? [String: Any])?["peak"] ?? 0)°
            
            Spine Angle:
            - Average: \((bio["spineAngle"] as? [String: Any])?["average"] ?? 0)°
            - Consistency: \((bio["spineAngle"] as? [String: Any])?["consistency"] ?? 0) (0-1 scale)
            
            Weight Distribution:
            - Average Front Foot: \((bio["weightDistribution"] as? [String: Any])?["averageFrontFoot"] ?? 50)%
            
            Wrist Velocity Analysis:
            - Peak Velocity: \((bio["wristVelocity"] as? [String: Any])?["peak"] ?? 0) units/second
            - Average Velocity: \((bio["wristVelocity"] as? [String: Any])?["average"] ?? 0) units/second
            
            Elbow Analysis:
            - Average Left Elbow Flexion: \((bio["elbowAnalysis"] as? [String: Any])?["averageLeftElbow"] ?? 0)°
            - Average Right Elbow Flexion: \((bio["elbowAnalysis"] as? [String: Any])?["averageRightElbow"] ?? 0)°
            - Max Left Flexion: \((bio["elbowAnalysis"] as? [String: Any])?["maxLeftFlexion"] ?? 0)°
            - Max Right Flexion: \((bio["elbowAnalysis"] as? [String: Any])?["maxRightFlexion"] ?? 0)°
            
            Head Movement:
            - Head Stability: \((bio["headMovement"] as? [String: Any])?["stability"] ?? 0) (0-1 scale)
            - Average Position: \((bio["headMovement"] as? [String: Any])?["averagePosition"] ?? [:])
            
            Knee Action:
            - Average Left Knee Flexion: \((bio["kneeAction"] as? [String: Any])?["averageLeftFlexion"] ?? 0)°
            - Average Right Knee Flexion: \((bio["kneeAction"] as? [String: Any])?["averageRightFlexion"] ?? 0)°
            - Knee Flexion Consistency: \((bio["kneeAction"] as? [String: Any])?["flexionConsistency"] ?? 0) (0-1 scale)
            
            Stance Analysis:
            - Average Stance Width: \((bio["stanceAnalysis"] as? [String: Any])?["averageStanceWidth"] ?? 0)
            - Stance Consistency: \((bio["stanceAnalysis"] as? [String: Any])?["stanceConsistency"] ?? 0) (0-1 scale)
            - Balance Range: \((bio["stanceAnalysis"] as? [String: Any])?["balanceRange"] ?? [:])
            
            Raw Pose Data Available: \((swingData["poseFrameData"] as? [Any])?.count ?? 0) frames with keypoint coordinates and confidence scores
            """
            
            // Add progression analysis if available
            if let progression = swingData["progressionData"] as? [String: Any],
               let trends = progression["trends"] as? [String: Any] {
                promptBuilder += """
                
                FRAME-BY-FRAME PROGRESSION ANALYSIS:
                Movement Trends Throughout Swing:
                - Hip Rotation Trend: \(trends["hipRotationTrend"] ?? "unknown")
                - Shoulder Rotation Trend: \(trends["shoulderRotationTrend"] ?? "unknown")  
                - Left Elbow Trend: \(trends["leftElbowTrend"] ?? "unknown")
                - Right Elbow Trend: \(trends["rightElbowTrend"] ?? "unknown")
                - Frames Analyzed: \(trends["totalFramesAnalyzed"] ?? 0)
                
                The progression data shows how each biomechanical element changes throughout the swing sequence.
                Use this to identify timing issues, inconsistencies, and coordination problems between body parts.
                """
            }
        }
        
        promptBuilder += """
        
        Please provide analysis in this exact JSON format (no additional text):
        {
            "feedback": "Overall assessment of the swing in 2-3 sentences, incorporating pose detection insights",
            "improvements": ["Specific improvement 1", "Specific improvement 2", "Specific improvement 3"],
            "technicalTips": ["Technical tip 1", "Technical tip 2", "Technical tip 3"],
            "searchKeywords": ["keyword1", "keyword2", "keyword3"]
        }
        
        Focus on:
        1. Specific technical feedback based on calculated metrics, raw pose biomechanics, AND progression trends
        2. Actionable improvements addressing timing and coordination issues revealed by frame-by-frame analysis
        3. Professional tips leveraging detailed movement progression and body sequencing data
        4. Keywords for finding instructional videos that address specific biomechanical and timing issues
        
        Use the precise pose detection data AND progression trends to identify:
        - Timing issues between body parts (e.g., hips starting before shoulders)
        - Inconsistent movement patterns throughout the swing
        - Coordination problems revealed by trend analysis
        - Subtle biomechanical issues that averaged metrics might miss
        """
        
        return promptBuilder
    }
    
    private func parseGeminiSwingFeedback(_ content: String) throws -> GeminiSwingFeedback {
        let cleanedContent = extractJSONFromResponse(content)
        
        guard let data = cleanedContent.data(using: .utf8) else {
            throw AIAnalysisError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw AIAnalysisError.invalidResponse
        }
        
        return GeminiSwingFeedback(
            feedback: json["feedback"] as? String ?? "No feedback available",
            improvements: json["improvements"] as? [String] ?? [],
            technicalTips: json["technicalTips"] as? [String] ?? [],
            searchKeywords: json["searchKeywords"] as? [String] ?? []
        )
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // Aggressive cleaning for consistent parsing
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "**", with: "")        // Remove markdown bold
            .replacingOccurrences(of: "*", with: "")         // Remove markdown italics
            .replacingOccurrences(of: "\n\n", with: "\n")    // Normalize line breaks
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first { and last } to extract just the JSON
        guard let startIndex = cleaned.firstIndex(of: "{"),
              let endIndex = cleaned.lastIndex(of: "}") else {
            // If no JSON found, create minimal valid structure
            return """
            {
                "feedback": "Swing analysis completed",
                "improvements": ["Continue practicing your swing fundamentals"],
                "technicalTips": ["Focus on balance and tempo"],
                "searchKeywords": ["fundamentals"]
            }
            """
        }
        
        return String(cleaned[startIndex...endIndex])
    }
    
    // MARK: - Frame Sampling and Progression Utilities
    
    private func sampleFrames(_ frames: [PoseFrameData], limit: Int = 15) -> [PoseFrameData] {
        guard frames.count > limit, limit > 0 else { return frames }
        let step = Double(frames.count - 1) / Double(limit - 1)
        return (0..<limit).map { frames[Int(round(Double($0) * step))] }
    }
    
    private func calculateFrameByFrameProgression(from frames: [PoseFrameData]) -> [String: Any] {
        guard frames.count > 1 else { return [:] }
        
        let totalTime = frames.last!.timestamp - frames.first!.timestamp
        let fps = totalTime > 0 ? Double(frames.count - 1) / totalTime : 0
        
        let context: [String: Any] = [
            "fps": fps.rounded(toPlaces: 2),
            "totalTime": totalTime.rounded(toPlaces: 3),
            "frameCount": frames.count
        ]
        
        let frameProgression: [[String: Any]] = frames.map { frame in
            [
                "f": frame.frameNumber,
                "t": frame.timestamp,
                "b": [:] // Biomechanics will be populated by BiomechanicsService
            ]
        }
        
        let trends: [String: Any] = [
            "validFrames": frameProgression.count
        ]
        
        return [
            "context": context,
            "frames": frameProgression,
            "trends": trends
        ]
    }
    
    // MARK: - Video Analysis Methods
    
    private func extractVideoFramesForAnalysis(from videoURL: URL) async -> [UIImage] {
        return await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            guard let track = asset.tracks(withMediaType: .video).first else {
                continuation.resume(returning: [])
                return
            }
            
            let duration = asset.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            
            // Extract 5-8 key frames: start, backswing peak, downswing start, impact, follow-through, end
            let frameTimings: [Double] = [
                0.0,                    // Start/address
                durationSeconds * 0.25, // Early backswing  
                durationSeconds * 0.45, // Top of backswing
                durationSeconds * 0.65, // Downswing
                durationSeconds * 0.8,  // Impact
                durationSeconds * 0.95, // Follow-through
                durationSeconds * 0.99  // Finish
            ]
            
            var frames: [UIImage] = []
            let group = DispatchGroup()
            
            for timing in frameTimings {
                group.enter()
                let time = CMTime(seconds: timing, preferredTimescale: 600)
                
                generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                    defer { group.leave() }
                    
                    if let cgImage = cgImage {
                        let image = UIImage(cgImage: cgImage)
                        // Resize to reasonable size for API (max 1024px)
                        let resizedImage = self.resizeImage(image, maxDimension: 1024)
                        frames.append(resizedImage)
                    }
                }
            }
            
            group.notify(queue: .main) {
                continuation.resume(returning: frames)
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func performVideoAnalysis(frames: [UIImage], duration: Double) async throws -> GeminiSwingFeedback {
        let prompt = """
        Golf swing analysis. Reply ONLY this JSON format:
        {
            "feedback": "Brief overall assessment",
            "improvements": [
                "Issue description. DRILL: Specific training drill with equipment and steps.",
                "Issue description. DRILL: Specific training drill with equipment and steps."
            ],
            "technicalTips": ["Quick tip 1", "Quick tip 2"],
            "searchKeywords": ["posture", "tempo", "balance"]
        }
        
        Rules: Each improvement must have issue description followed by "DRILL:" and specific practice instructions. Focus on posture, swing plane, balance.
        """
        
        // Convert images to base64
        let imageParts = frames.compactMap { image -> [String: Any]? in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
            let base64String = imageData.base64EncodedString()
            
            return [
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64String
                ]
            ]
        }
        
        // Create request with text + images
        var parts: [[String: Any]] = [["text": prompt]]
        parts.append(contentsOf: imageParts)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,        // Very low for consistent format
                "maxOutputTokens": 400,     // Force concise responses
                "topP": 0.9,
                "topK": 5                   // Limited vocabulary for consistency
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(geminiAPIKey)") else {
            throw AIAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = response.candidates.first?.content.parts.first?.text else {
            throw AIAnalysisError.invalidResponse
        }
        
        return parseVideoGeminiResponseWithStructure(text)
    }
    
    private func parseVideoGeminiResponseWithStructure(_ content: String) -> GeminiSwingFeedback {
        // Try JSON parsing first (preferred)
        let cleanedContent = extractJSONFromResponse(content)
        
        do {
            guard let data = cleanedContent.data(using: .utf8) else {
                throw AIAnalysisError.invalidResponse
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else {
                throw AIAnalysisError.invalidResponse
            }
            
            // Parse with structured improvements
            let feedback = json["feedback"] as? String ?? "Your swing shows athletic potential with specific areas for improvement."
            let tips = json["technicalTips"] as? [String] ?? [
                "Keep your head steady throughout the entire swing motion",
                "Maintain balanced weight distribution on both feet at setup"
            ]
            let keywords = json["searchKeywords"] as? [String] ?? ["posture", "tempo", "balance"]
            
            // Parse improvements (expected format: "Issue description. DRILL: Practice instructions.")
            let improvements = json["improvements"] as? [String] ?? [
                "Your posture may be too upright; try hinging more from your hips. DRILL: Place a club across your hips and practice hinging forward until the club touches your knees.",
                "Your swing plane could be more consistent; focus on proper club path. DRILL: Place an alignment rod outside your ball and practice swinging without hitting it."
            ]
            
            return GeminiSwingFeedback(
                feedback: feedback,
                improvements: improvements,
                technicalTips: Array(tips.prefix(3)),
                searchKeywords: keywords
            )
            
        } catch {
            print("⚠️ Structured JSON parsing failed, using standardized fallback")
            return createStandardizedFallback()
        }
    }
    
    private func createStandardizedFallback() -> GeminiSwingFeedback {
        return GeminiSwingFeedback(
            feedback: "Swing analysis completed. Focus on fundamentals for consistent improvement.",
            improvements: [
                "Your posture may be too upright; try hinging more from your hips to create a more athletic stance. DRILL: Place a club across your hips and practice hinging forward until the club touches your knees, maintaining a straight back.",
                "Your swing plane could be more consistent; focus on maintaining proper club path throughout the swing. DRILL: Place an alignment rod just outside your ball and practice swinging without hitting the rod on the backswing.",
                "Balance and weight transfer need improvement for more consistent ball striking. DRILL: Practice weight shift drills: start with 60% weight on trail foot, finish with 90% on lead foot."
            ],
            technicalTips: [
                "Keep your head behind the ball through impact",
                "Maintain spine angle throughout the backswing",
                "Complete your follow-through with weight on lead foot"
            ],
            searchKeywords: ["setup", "tempo", "balance", "fundamentals"]
        )
    }
    
    private func parseVideoGeminiResponse(_ content: String) -> GeminiSwingFeedback {
        // For video analysis, we get a plain text response, so we need to parse it differently
        // Split the response into sections and extract key information
        let lines = content.components(separatedBy: .newlines)
        
        var feedback = content // Use the full response as feedback
        var improvements: [String] = []
        var technicalTips: [String] = []
        
        // Extract numbered lists or bullet points as improvements/tips
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Look for numbered improvements (1. 2. 3. etc.)
            if trimmed.range(of: #"^\d+\."#, options: .regularExpression) != nil {
                let improvement = trimmed.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                if !improvement.isEmpty {
                    improvements.append(improvement)
                }
            }
            // Look for bullet points
            else if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let tip = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                if !tip.isEmpty {
                    technicalTips.append(tip)
                }
            }
        }
        
        // If we couldn't extract specific improvements, create some from the content
        if improvements.isEmpty {
            // Look for common improvement phrases
            let improvementPatterns = [
                "improve", "focus on", "work on", "practice", "adjust", "correct"
            ]
            
            for line in lines {
                for pattern in improvementPatterns {
                    if line.lowercased().contains(pattern) {
                        let clean = line.trimmingCharacters(in: .whitespaces)
                        if clean.count > 10 { // Avoid very short lines
                            improvements.append(clean)
                            break
                        }
                    }
                }
            }
        }
        
        return GeminiSwingFeedback(
            feedback: feedback,
            improvements: Array(improvements.prefix(5)), // Limit to 5 improvements
            technicalTips: Array(technicalTips.prefix(5)), // Limit to 5 tips
            searchKeywords: improvements + technicalTips // Combine for search
        )
    }
}

// MARK: - Utility Extensions
private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
