//
//  AIAnalysisService.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import EventKit
import AVFoundation

struct CalendarAnalysisResult {
    let isGolfRelated: Bool
    let confidence: Double
    let extractedCourseName: String?
    let extractedPlayerCount: Int?
    let golfType: GolfEventType?
    let recommendations: [String]
}

enum GolfEventType: String, CaseIterable {
    case teeTime = "Tee Time"
    case lesson = "Golf Lesson"
    case tournament = "Tournament"
    case practice = "Practice Session"
    case outing = "Golf Outing"
    case meeting = "Golf Meeting"
}

class AIAnalysisService: ObservableObject {
    private let geminiAPIKey: String
    private let youtubeService: YouTubeService?
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
    
    init() {
        guard let geminiAPIKey = APIConfiguration.shared.geminiAPIKey else {
            fatalError("Gemini API key not configured")
        }
        
        self.geminiAPIKey = geminiAPIKey
        
        // YouTube service is optional - if no API key, disable YouTube recommendations
        if let youtubeAPIKey = APIConfiguration.shared.youtubeAPIKey {
            self.youtubeService = YouTubeService(apiKey: youtubeAPIKey)
        } else {
            self.youtubeService = nil
            print("⚠️ YouTube recommendations disabled: No YouTube API key configured")
        }
    }
    
    // Legacy initializer for backward compatibility
    convenience init(apiKey: String) {
        self.init()
    }
    
    func analyzeCalendarEvent(_ event: EKEvent) async -> CalendarAnalysisResult {
        let eventData = prepareEventData(event)
        
        do {
            let analysis = try await performAIAnalysis(eventData: eventData)
            return analysis
        } catch {
            print("AI Analysis error: \(error)")
            return fallbackAnalysis(event)
        }
    }
    
    private func prepareEventData(_ event: EKEvent) -> [String: Any] {
        return [
            "title": event.title ?? "",
            "location": event.location ?? "",
            "notes": event.notes ?? "",
            "startDate": event.startDate.ISO8601Format(),
            "endDate": event.endDate.ISO8601Format(),
            "duration": event.endDate.timeIntervalSince(event.startDate)
        ]
    }
    
    private func performAIAnalysis(eventData: [String: Any]) async throws -> CalendarAnalysisResult {
        let prompt = createAnalysisPrompt(eventData: eventData)
        
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
                "temperature": 0.3,
                "maxOutputTokens": 500,
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
        
        return try parseAnalysisResponse(content)
    }
    
    private func createAnalysisPrompt(eventData: [String: Any]) -> String {
        return """
        You are an expert at analyzing calendar events to identify golf-related activities. Analyze this calendar event to determine if it's golf-related and extract relevant information:
        
        Event Details:
        - Title: \(eventData["title"] ?? "")
        - Location: \(eventData["location"] ?? "")
        - Notes: \(eventData["notes"] ?? "")
        - Start: \(eventData["startDate"] ?? "")
        - Duration: \(eventData["duration"] ?? 0) seconds
        
        Please analyze and return ONLY valid JSON with this exact format (no additional text):
        {
            "isGolfRelated": boolean,
            "confidence": number (0.0-1.0),
            "extractedCourseName": string or null,
            "extractedPlayerCount": number or null,
            "golfType": "Tee Time" | "Golf Lesson" | "Tournament" | "Practice Session" | "Golf Outing" | "Golf Meeting" | null,
            "recommendations": [string array of helpful suggestions]
        }
        
        Look for keywords like: golf, tee time, course, country club, driving range, putting, lesson, tournament, scramble, outing.
        Extract golf course names from location or title.
        Determine player count from phrases like "foursome", "2 players", etc.
        Provide recommendations for preparation or equipment needed.
        """
    }
    
    private func parseAnalysisResponse(_ content: String) throws -> CalendarAnalysisResult {
        // Clean the response to extract just the JSON part
        let cleanedContent = extractJSONFromResponse(content)
        
        guard let data = cleanedContent.data(using: .utf8) else {
            throw AIAnalysisError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw AIAnalysisError.invalidResponse
        }
        
        return CalendarAnalysisResult(
            isGolfRelated: json["isGolfRelated"] as? Bool ?? false,
            confidence: json["confidence"] as? Double ?? 0.0,
            extractedCourseName: json["extractedCourseName"] as? String,
            extractedPlayerCount: json["extractedPlayerCount"] as? Int,
            golfType: GolfEventType(rawValue: json["golfType"] as? String ?? ""),
            recommendations: json["recommendations"] as? [String] ?? []
        )
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // Remove any markdown code block markers
        let withoutCodeBlocks = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first { and last } to extract just the JSON
        guard let startIndex = withoutCodeBlocks.firstIndex(of: "{"),
              let endIndex = withoutCodeBlocks.lastIndex(of: "}") else {
            return withoutCodeBlocks
        }
        
        return String(withoutCodeBlocks[startIndex...endIndex])
    }
    
    private func fallbackAnalysis(_ event: EKEvent) -> CalendarAnalysisResult {
        let title = event.title?.lowercased() ?? ""
        let location = event.location?.lowercased() ?? ""
        let combinedText = "\(title) \(location)"
        
        let golfKeywords = ["golf", "tee", "course", "country club", "links"]
        let isGolfRelated = golfKeywords.contains { combinedText.contains($0) }
        
        return CalendarAnalysisResult(
            isGolfRelated: isGolfRelated,
            confidence: isGolfRelated ? 0.7 : 0.1,
            extractedCourseName: event.location,
            extractedPlayerCount: nil,
            golfType: isGolfRelated ? .teeTime : nil,
            recommendations: isGolfRelated ? ["Check weather conditions", "Prepare golf equipment"] : []
        )
    }
    
    // MARK: - Video Analysis Methods
    
    func analyzeSwingWithGemini(_ analysisResult: VideoAnalysisResult, poseFrameData: [PoseFrameData]? = nil) async -> GeminiSwingAnalysis? {
        let swingData = prepareSwingDataForGemini(analysisResult, poseFrameData: poseFrameData)
        
        do {
            let geminiAnalysis = try await performGeminiSwingAnalysis(swingData: swingData)
            
            // Get YouTube recommendations based on Gemini analysis
            let youtubeRecommendations = await getYouTubeRecommendations(for: geminiAnalysis)
            
            return GeminiSwingAnalysis(
                feedback: geminiAnalysis.feedback,
                improvements: geminiAnalysis.improvements,
                technicalTips: geminiAnalysis.technicalTips,
                youtubeRecommendations: youtubeRecommendations
            )
        } catch {
            print("Gemini swing analysis error: \(error)")
            return nil
        }
    }
    
    private func prepareSwingDataForGemini(_ result: VideoAnalysisResult, poseFrameData: [PoseFrameData]? = nil) -> [String: Any] {
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
            ]
        ]
        
        // Add raw pose frame data if available
        if let poseFrames = poseFrameData {
            let sampledFrames = sampleFrames(poseFrames, limit: 15) // Reduced to 15 frames to stay under 30KB token limit
            
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
            swingData["biomechanics"] = calculateDetailedBiomechanics(from: poseFrames)
            
            // Add frame-by-frame progression data
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
    
    private func calculateDetailedBiomechanics(from frames: [PoseFrameData]) -> [String: Any] {
        guard !frames.isEmpty else { return [:] }
        
        var hipAngles: [Double] = []
        var shoulderAngles: [Double] = []
        var spineAngles: [Double] = []
        var weightDistributions: [(front: Double, back: Double)] = []
        var wristVelocities: [Double] = []
        var elbowAngles: [(left: Double, right: Double)] = []
        var headPositions: [CGPoint] = []
        var kneeFlexions: [(left: Double, right: Double)] = []
        var stanceMetrics: [(width: Double, balance: Double)] = []
        
        for frame in frames {
            if let hipAngle = calculateHipAngle(frame: frame) {
                hipAngles.append(hipAngle)
            }
            
            if let shoulderAngle = calculateShoulderAngle(frame: frame) {
                shoulderAngles.append(shoulderAngle)
            }
            
            if let spineAngle = calculateSpineAngle(frame: frame) {
                spineAngles.append(spineAngle)
            }
            
            let weightDist = calculateWeightDistribution(frame: frame)
            weightDistributions.append(weightDist)
            
            if let velocity = calculateWristVelocity(frame: frame, in: frames) {
                wristVelocities.append(velocity)
            }
            
            let elbowAngle = calculateElbowAngles(frame: frame)
            elbowAngles.append(elbowAngle)
            
            let headPos = calculateHeadPosition(frame: frame)
            headPositions.append(headPos)
            
            let kneeFlexion = calculateKneeFlexion(frame: frame)
            kneeFlexions.append(kneeFlexion)
            
            let stance = calculateStanceMetrics(frame: frame)
            stanceMetrics.append(stance)
        }
        
        // Build biomechanics dictionary step by step to avoid compiler complexity
        var biomechanics: [String: Any] = [:]
        
        biomechanics["hipRotation"] = [
            "angles": hipAngles,
            "average": hipAngles.isEmpty ? 0 : hipAngles.reduce(0, +) / Double(hipAngles.count),
            "peak": hipAngles.max() ?? 0
        ]
        
        biomechanics["shoulderRotation"] = [
            "angles": shoulderAngles,
            "average": shoulderAngles.isEmpty ? 0 : shoulderAngles.reduce(0, +) / Double(shoulderAngles.count),
            "peak": shoulderAngles.max() ?? 0
        ]
        
        biomechanics["spineAngle"] = [
            "angles": spineAngles,
            "average": spineAngles.isEmpty ? 0 : spineAngles.reduce(0, +) / Double(spineAngles.count),
            "consistency": calculateBiomechanicalConsistency(spineAngles)
        ]
        
        biomechanics["weightDistribution"] = [
            "frontFootPercentages": weightDistributions.map { $0.front },
            "backFootPercentages": weightDistributions.map { $0.back },
            "averageFrontFoot": weightDistributions.isEmpty ? 50 : weightDistributions.map { $0.front }.reduce(0, +) / Double(weightDistributions.count)
        ]
        
        biomechanics["wristVelocity"] = [
            "velocities": wristVelocities,
            "peak": wristVelocities.max() ?? 0,
            "average": wristVelocities.isEmpty ? 0 : wristVelocities.reduce(0, +) / Double(wristVelocities.count)
        ]
        
        let leftElbowValues = elbowAngles.map { $0.left }
        let rightElbowValues = elbowAngles.map { $0.right }
        biomechanics["elbowAnalysis"] = [
            "leftElbowAngles": leftElbowValues,
            "rightElbowAngles": rightElbowValues,
            "averageLeftElbow": elbowAngles.isEmpty ? 0 : leftElbowValues.reduce(0, +) / Double(leftElbowValues.count),
            "averageRightElbow": elbowAngles.isEmpty ? 0 : rightElbowValues.reduce(0, +) / Double(rightElbowValues.count),
            "maxLeftFlexion": leftElbowValues.max() ?? 0,
            "maxRightFlexion": rightElbowValues.max() ?? 0
        ]
        
        biomechanics["headMovement"] = [
            "positions": headPositions.map { ["x": $0.x, "y": $0.y] },
            "stability": calculateHeadStability(headPositions),
            "averagePosition": calculateAveragePosition(headPositions)
        ]
        
        let leftKneeValues = kneeFlexions.map { $0.left }
        let rightKneeValues = kneeFlexions.map { $0.right }
        let avgKneeFlexions = kneeFlexions.map { ($0.left + $0.right) / 2 }
        biomechanics["kneeAction"] = [
            "leftKneeFlexions": leftKneeValues,
            "rightKneeFlexions": rightKneeValues,
            "averageLeftFlexion": kneeFlexions.isEmpty ? 0 : leftKneeValues.reduce(0, +) / Double(leftKneeValues.count),
            "averageRightFlexion": kneeFlexions.isEmpty ? 0 : rightKneeValues.reduce(0, +) / Double(rightKneeValues.count),
            "maxLeftFlexion": leftKneeValues.max() ?? 0,
            "maxRightFlexion": rightKneeValues.max() ?? 0,
            "flexionConsistency": calculateBiomechanicalConsistency(avgKneeFlexions)
        ]
        
        let stanceWidthValues = stanceMetrics.map { $0.width }
        let balanceValues = stanceMetrics.map { $0.balance }
        biomechanics["stanceAnalysis"] = [
            "stanceWidths": stanceWidthValues,
            "balanceShifts": balanceValues,
            "averageStanceWidth": stanceMetrics.isEmpty ? 0 : stanceWidthValues.reduce(0, +) / Double(stanceWidthValues.count),
            "stanceConsistency": calculateBiomechanicalConsistency(stanceWidthValues),
            "balanceRange": ["min": balanceValues.min() ?? 0, "max": balanceValues.max() ?? 0]
        ]
        
        return biomechanics
    }
    
    private func calculateHipAngle(frame: PoseFrameData) -> Double? {
        guard frame.keypoints.count >= 13,
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { return nil } // right hip
        
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        let hipVector = CGPoint(x: rightHip.x - leftHip.x, y: rightHip.y - leftHip.y)
        let angle = atan2(hipVector.y, hipVector.x) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateShoulderAngle(frame: PoseFrameData) -> Double? {
        guard frame.keypoints.count >= 13,
              frame.keypoints[1] != .zero, // left shoulder
              frame.keypoints[2] != .zero else { return nil } // right shoulder
        
        let leftShoulder = frame.keypoints[1]
        let rightShoulder = frame.keypoints[2]
        
        let shoulderVector = CGPoint(x: rightShoulder.x - leftShoulder.x, y: rightShoulder.y - leftShoulder.y)
        let angle = atan2(shoulderVector.y, shoulderVector.x) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateSpineAngle(frame: PoseFrameData) -> Double? {
        guard frame.keypoints.count >= 13,
              frame.keypoints[0] != .zero, // nose
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { return nil } // right hip
        
        let nose = frame.keypoints[0]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        let midHip = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        
        let spineVector = CGPoint(x: nose.x - midHip.x, y: nose.y - midHip.y)
        let angle = atan2(spineVector.x, spineVector.y) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateWeightDistribution(frame: PoseFrameData) -> (front: Double, back: Double) {
        guard frame.keypoints.count >= 13,
              frame.keypoints[9] != .zero, // left ankle
              frame.keypoints[10] != .zero, // right ankle
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { return (50, 50) } // right hip
        
        let leftAnkle = frame.keypoints[9]
        let rightAnkle = frame.keypoints[10]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        let _ = CGPoint(x: (leftAnkle.x + rightAnkle.x) / 2, y: (leftAnkle.y + rightAnkle.y) / 2)
        let hipCenter = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        
        let totalWidth = abs(rightAnkle.x - leftAnkle.x)
        let frontWeight = totalWidth > 0 ? abs(hipCenter.x - leftAnkle.x) / totalWidth * 100 : 50
        return (front: frontWeight, back: 100 - frontWeight)
    }
    
    private func calculateWristVelocity(frame: PoseFrameData, in allFrames: [PoseFrameData]) -> Double? {
        guard let currentIndex = allFrames.firstIndex(where: { $0.frameNumber == frame.frameNumber }),
              currentIndex > 0,
              frame.keypoints.count >= 13,
              frame.keypoints[5] != .zero else { return nil } // left wrist
        
        let previousFrame = allFrames[currentIndex - 1]
        guard previousFrame.keypoints.count >= 13,
              previousFrame.keypoints[5] != .zero else { return nil }
        
        let currentWrist = frame.keypoints[5]
        let previousWrist = previousFrame.keypoints[5]
        let timeInterval = frame.timestamp - previousFrame.timestamp
        
        guard timeInterval > 0 else { return nil }
        
        let dx = currentWrist.x - previousWrist.x
        let dy = currentWrist.y - previousWrist.y
        let velocity = sqrt(dx * dx + dy * dy) / timeInterval
        
        return velocity
    }
    
    private func calculateBiomechanicalConsistency(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 1.0 }
        
        let average = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - average, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        return max(0, 1.0 - (standardDeviation / average))
    }
    
    private func getYouTubeRecommendations(for analysis: GeminiSwingFeedback) async -> [GolfYouTubeRecommendation] {
        guard let youtubeService = youtubeService else {
            print("ℹ️ YouTube recommendations disabled: No YouTube API key configured")
            return []
        }
        
        var recommendations: [GolfYouTubeRecommendation] = []
        
        let searchQueries = analysis.searchKeywords + analysis.improvements.map { improvement in
            "golf \(improvement) drill"
        }
        
        for query in Array(searchQueries.prefix(3)) {
            do {
                let videos = try await youtubeService.searchVideos(query: query, maxResults: 2)
                let golfRecommendations = videos.map { video in
                    GolfYouTubeRecommendation(
                        video: video,
                        relevanceScore: calculateRelevanceScore(query: query, video: video),
                        improvementArea: categorizeVideoToImprovementArea(from: query, video: video),
                        reason: generateRecommendationReason(from: query, video: video)
                    )
                }
                recommendations.append(contentsOf: golfRecommendations)
            } catch {
                print("YouTube search error for '\(query)': \(error)")
            }
        }
        
        return Array(recommendations.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(6))
    }
    
    private func categorizeVideoToImprovementArea(from query: String, video: YouTubeVideo) -> GolfYouTubeRecommendation.ImprovementArea {
        let queryLower = query.lowercased()
        let titleLower = video.snippet.title.lowercased()
        
        if queryLower.contains("drill") || titleLower.contains("drill") || titleLower.contains("exercise") {
            return .general
        } else if queryLower.contains("swing plane") || titleLower.contains("swing plane") {
            return .backswing
        } else if queryLower.contains("tempo") || titleLower.contains("tempo") || titleLower.contains("rhythm") {
            return .tempo
        } else if queryLower.contains("balance") || titleLower.contains("balance") || titleLower.contains("weight shift") {
            return .balance
        } else if queryLower.contains("power") || titleLower.contains("power") || titleLower.contains("distance") {
            return .driving
        } else {
            return .general
        }
    }
    
    private func calculateRelevanceScore(query: String, video: YouTubeVideo) -> Double {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let titleWords = video.snippet.title.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let descriptionWords = video.snippet.description.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        var score = 0.0
        
        for queryWord in queryWords {
            if titleWords.contains(queryWord) {
                score += 2.0
            }
        }
        
        for queryWord in queryWords {
            if descriptionWords.contains(queryWord) {
                score += 1.0
            }
        }
        
        let golfChannels = ["Golf Digest", "PGA Tour", "Golf.com", "Rick Shiels Golf", "Me And My Golf", "Golf Monthly"]
        if golfChannels.contains(where: { video.snippet.channelTitle.contains($0) }) {
            score += 3.0
        }
        
        return score
    }
    
    private func generateRecommendationReason(from query: String, video: YouTubeVideo) -> String {
        return "This video addresses your \(query) needs based on your swing analysis."
    }
    
    // MARK: - Additional Biomechanical Calculations
    
    private func calculateElbowAngles(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftElbow: Double = 0
        var rightElbow: Double = 0
        
        // Left elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count >= 17,
           frame.keypoints[1] != .zero, // left shoulder
           frame.keypoints[3] != .zero, // left elbow  
           frame.keypoints[5] != .zero { // left wrist
            leftElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[1], // shoulder
                vertex: frame.keypoints[3], // elbow
                p3: frame.keypoints[5] // wrist
            )
        }
        
        // Right elbow angle (shoulder-elbow-wrist)
        if frame.keypoints.count >= 17,
           frame.keypoints[2] != .zero, // right shoulder
           frame.keypoints[4] != .zero, // right elbow
           frame.keypoints[6] != .zero { // right wrist
            rightElbow = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[2], // shoulder
                vertex: frame.keypoints[4], // elbow
                p3: frame.keypoints[6] // wrist
            )
        }
        
        return (left: leftElbow, right: rightElbow)
    }
    
    private func calculateHeadPosition(frame: PoseFrameData) -> CGPoint {
        guard frame.keypoints.count >= 13,
              frame.keypoints[0] != .zero else { 
            return CGPoint.zero 
        }
        
        return frame.keypoints[0] // nose position as head reference
    }
    
    private func calculateKneeFlexion(frame: PoseFrameData) -> (left: Double, right: Double) {
        var leftKnee: Double = 0
        var rightKnee: Double = 0
        
        // Left knee flexion (hip-knee-ankle)
        if frame.keypoints.count >= 13,
           frame.keypoints[7] != .zero, // left hip
           frame.keypoints[9] != .zero, // left knee
           frame.keypoints[11] != .zero { // left ankle
            leftKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[7], // hip
                vertex: frame.keypoints[9], // knee
                p3: frame.keypoints[11] // ankle
            )
        }
        
        // Right knee flexion (hip-knee-ankle)
        if frame.keypoints.count >= 13,
           frame.keypoints[8] != .zero, // right hip
           frame.keypoints[10] != .zero, // right knee
           frame.keypoints[12] != .zero { // right ankle
            rightKnee = calculateAngleBetweenThreePoints(
                p1: frame.keypoints[8], // hip
                vertex: frame.keypoints[10], // knee
                p3: frame.keypoints[12] // ankle
            )
        }
        
        return (left: leftKnee, right: rightKnee)
    }
    
    private func calculateStanceMetrics(frame: PoseFrameData) -> (width: Double, balance: Double) {
        guard frame.keypoints.count >= 13,
              frame.keypoints[11] != .zero, // left ankle
              frame.keypoints[12] != .zero, // right ankle
              frame.keypoints[7] != .zero, // left hip
              frame.keypoints[8] != .zero else { // right hip
            return (width: 0, balance: 0)
        }
        
        let leftAnkle = frame.keypoints[11]
        let rightAnkle = frame.keypoints[12]
        let leftHip = frame.keypoints[7]
        let rightHip = frame.keypoints[8]
        
        // Stance width (distance between ankles)
        let stanceWidth = sqrt(pow(rightAnkle.x - leftAnkle.x, 2) + pow(rightAnkle.y - leftAnkle.y, 2))
        
        // Balance calculation (center of mass relative to feet)
        let hipCenter = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
        let footCenter = CGPoint(x: (leftAnkle.x + rightAnkle.x) / 2, y: (leftAnkle.y + rightAnkle.y) / 2)
        let balanceOffset = sqrt(pow(hipCenter.x - footCenter.x, 2) + pow(hipCenter.y - footCenter.y, 2))
        
        return (width: stanceWidth, balance: balanceOffset)
    }
    
    private func calculateAngleBetweenThreePoints(p1: CGPoint, vertex: CGPoint, p3: CGPoint) -> Double {
        let vector1 = CGPoint(x: p1.x - vertex.x, y: p1.y - vertex.y)
        let vector2 = CGPoint(x: p3.x - vertex.x, y: p3.y - vertex.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        return acos(clampedCosAngle) * 180 / .pi
    }
    
    private func calculateHeadStability(_ positions: [CGPoint]) -> Double {
        guard positions.count > 1 else { return 1.0 }
        
        let distances: [Double] = positions.enumerated().compactMap { index, position in
            guard index > 0 else { return nil }
            let prev = positions[index - 1]
            return sqrt(pow(position.x - prev.x, 2) + pow(position.y - prev.y, 2))
        }
        
        let averageMovement = distances.isEmpty ? 0 : distances.reduce(0, +) / Double(distances.count)
        return max(0, 1.0 - (averageMovement * 10)) // Scale for 0-1 range
    }
    
    private func calculateAveragePosition(_ positions: [CGPoint]) -> [String: Double] {
        guard !positions.isEmpty else { return ["x": 0, "y": 0] }
        
        let avgX = positions.map { $0.x }.reduce(0, +) / Double(positions.count)
        let avgY = positions.map { $0.y }.reduce(0, +) / Double(positions.count)
        
        return ["x": avgX, "y": avgY]
    }
    
    private func calculateFrameByFrameProgression(from frames: [PoseFrameData]) -> [String: Any] {
        guard frames.count > 1 else { return [:] }
        
        // Calculate FPS and timing context
        let totalTime = frames.last!.timestamp - frames.first!.timestamp
        let fps = totalTime > 0 ? Double(frames.count - 1) / totalTime : 0
        
        let context: [String: Any] = [
            "fps": fps.rounded(toPlaces: 2),
            "totalTime": totalTime.rounded(toPlaces: 3),
            "startTimestamp": frames.first!.timestamp,
            "endTimestamp": frames.last!.timestamp,
            "cameraOrientation": "portrait", // TODO: Get actual camera orientation
            "frameCount": frames.count
        ]
        
        // Calculate biomechanics for each frame with proper nil handling
        let frameProgression: [[String: Any]] = frames.map { frame in
            var bio: [String: Any] = [:]
            
            // Only add metrics that have valid values (no ?? 0 bias)
            if let hip = calculateHipAngle(frame: frame) { bio["hipAngle"] = hip }
            if let shoulder = calculateShoulderAngle(frame: frame) { bio["shoulderAngle"] = shoulder }
            if let spine = calculateSpineAngle(frame: frame) { bio["spineAngle"] = spine }
            
            let elbowAngles = calculateElbowAngles(frame: frame)
            let kneeFlexion = calculateKneeFlexion(frame: frame)
            let headPos = calculateHeadPosition(frame: frame)
            let stance = calculateStanceMetrics(frame: frame)
            let weightDist = calculateWeightDistribution(frame: frame)
            
            // Only add non-zero values
            if elbowAngles.left > 0 { bio["leftElbow"] = elbowAngles.left }
            if elbowAngles.right > 0 { bio["rightElbow"] = elbowAngles.right }
            if kneeFlexion.left > 0 { bio["leftKnee"] = kneeFlexion.left }
            if kneeFlexion.right > 0 { bio["rightKnee"] = kneeFlexion.right }
            if headPos != .zero { 
                bio["headX"] = headPos.x
                bio["headY"] = headPos.y
            }
            if stance.width > 0 { bio["stanceWidth"] = stance.width }
            if stance.balance >= 0 { bio["balance"] = stance.balance }
            bio["weightFront"] = weightDist.front
            bio["weightBack"] = weightDist.back
            
            return [
                "f": frame.frameNumber,    // Shortened keys to save tokens
                "t": frame.timestamp,
                "b": bio
            ]
        }
        
        // Calculate trends with nil-safe extraction
        func extractMetric(_ key: String) -> [Double] {
            return frameProgression.compactMap { ($0["b"] as? [String: Any])?[key] as? Double }
        }
        
        let trends: [String: Any] = [
            "hip": calculateTrendWithSlope(extractMetric("hipAngle"), timespan: totalTime),
            "shoulder": calculateTrendWithSlope(extractMetric("shoulderAngle"), timespan: totalTime),
            "leftElbow": calculateTrendWithSlope(extractMetric("leftElbow"), timespan: totalTime),
            "rightElbow": calculateTrendWithSlope(extractMetric("rightElbow"), timespan: totalTime),
            "validFrames": frameProgression.count
        ]
        
        return [
            "context": context,
            "frames": frameProgression,
            "trends": trends
        ]
    }
    
    private func calculateTrend(_ values: [Double]) -> String {
        guard values.count >= 3 else { return "insufficient_data" }
        
        let firstThird = Array(values.prefix(values.count / 3))
        let lastThird = Array(values.suffix(values.count / 3))
        
        let firstAvg = firstThird.reduce(0, +) / Double(firstThird.count)
        let lastAvg = lastThird.reduce(0, +) / Double(lastThird.count)
        
        let change = lastAvg - firstAvg
        
        if abs(change) < 5 {
            return "stable"
        } else if change > 0 {
            return "increasing"
        } else {
            return "decreasing"
        }
    }
    
    private func calculateTrendWithSlope(_ values: [Double], timespan: TimeInterval) -> [String: Any] {
        guard values.count >= 3 else { 
            return ["trend": "insufficient_data", "slope": 0, "confidence": 0] 
        }
        
        let firstThird = Array(values.prefix(values.count / 3))
        let lastThird = Array(values.suffix(values.count / 3))
        
        let firstAvg = firstThird.reduce(0, +) / Double(firstThird.count)
        let lastAvg = lastThird.reduce(0, +) / Double(lastThird.count)
        
        let change = lastAvg - firstAvg
        let slope = timespan > 0 ? change / timespan : 0 // degrees per second
        
        var trend: String
        if abs(change) < 5 {
            trend = "stable"
        } else if change > 0 {
            trend = "increasing"
        } else {
            trend = "decreasing"
        }
        
        // Calculate confidence based on data consistency
        let standardDev = calculateStandardDeviation(values)
        let confidence = max(0, 1.0 - (standardDev / (values.max() ?? 1)))
        
        return [
            "trend": trend,
            "slope": slope.rounded(toPlaces: 2),
            "confidence": confidence.rounded(toPlaces: 2),
            "changeAmount": change.rounded(toPlaces: 1)
        ]
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let average = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - average, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    // MARK: - Frame Sampling
    private func sampleFrames(_ frames: [PoseFrameData], limit: Int = 15) -> [PoseFrameData] {
        guard frames.count > limit, limit > 0 else { return frames }
        let step = Double(frames.count - 1) / Double(limit - 1)
        return (0..<limit).map { frames[Int(round(Double($0) * step))] }
    }
    

    
    // MARK: - Testing Support
    #if DEBUG
    internal func performTestableProgression(_ frames: [PoseFrameData]) -> [String: Any] {
        return calculateFrameByFrameProgression(from: frames)
    }
    
    internal func sampleFramesForTesting(_ frames: [PoseFrameData], limit: Int) -> [PoseFrameData] {
        return sampleFrames(frames, limit: limit)
    }
    #endif
}

// MARK: - Utility Extensions
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Supporting Types
enum AIAnalysisError: Error {
    case invalidURL
    case noResponse
    case invalidResponse
}

// MARK: - Video Analysis Supporting Types

struct GeminiSwingAnalysis {
    let feedback: String
    let improvements: [String]
    let technicalTips: [String]
    let youtubeRecommendations: [GolfYouTubeRecommendation]
}

struct GeminiSwingFeedback {
    let feedback: String
    let improvements: [String]
    let technicalTips: [String]
    let searchKeywords: [String]
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
    }
}
