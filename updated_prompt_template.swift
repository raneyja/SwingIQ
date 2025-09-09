// Updated Gemini Prompt Template based on Oracle recommendations
// Replace the createSwingAnalysisPrompt function in GeminiAnalysisService.swift

private func createSwingAnalysisPrompt(swingData: [String: Any]) -> String {
    let hasPoseData = swingData["poseFrameData"] != nil
    let biomechanics = swingData["biomechanics"] as? [String: Any]
    let cameraView = swingData["cameraView"] as? String ?? "face-on"
    let frameRate = swingData["frameRate"] as? Int ?? 30
    
    var promptBuilder = """
    You are a PGA teaching professional analyzing a golf swing from single-camera video with pose-tracking data.
    
    ANALYSIS PRIORITIES (in order of importance):
    1. Impact alignments that correlate with ball flight
    2. Transition sequence and kinematic chain
    3. Backswing positions and setup
    
    INSTRUCTIONS:
    • Focus ONLY on metrics with confidence ≥ 0.7
    • Treat all numeric values as approximations from video analysis
    • Prioritize actionable improvements that affect ball striking
    • Provide ONE specific drill per improvement recommendation (max 20 words each)
    • Rank improvements by expected impact on ball flight
    
    Camera Setup: \(cameraView) view, \(frameRate) fps
    Duration: \((swingData["frameAnalytics"] as? [String: Any])?["duration"] ?? 0) seconds
    Total Frames: \((swingData["frameAnalytics"] as? [String: Any])?["totalFrames"] ?? 0)
    
    Core Swing Metrics:
    - Tempo Ratio: \((swingData["metrics"] as? [String: Any])?["tempo"] ?? 0):1 (backswing:downswing)
    - Overall Balance Score: \((swingData["metrics"] as? [String: Any])?["balance"] ?? 0) (0-1 scale)
    """
    
    if hasPoseData, let bio = biomechanics {
        let confidences = bio["metricConfidences"] as? [String: Double] ?? [:]
        
        promptBuilder += """
        
        HIGH-CONFIDENCE BIOMECHANICAL ANALYSIS (≥0.7 confidence only):
        """
        
        // Head Movement (typically high confidence)
        if (confidences["headStability"] ?? 1.0) >= 0.7 {
            promptBuilder += """
            
            Head Movement (Confidence: \(String(format: "%.1f", confidences["headStability"] ?? 1.0))):
            - Head Stability Score: \((bio["headMovement"] as? [String: Any])?["stability"] ?? 0) (0-1 scale)
            - Horizontal Sway: \((bio["headMovement"] as? [String: Any])?["horizontalSway"] ?? 0) cm
            - Vertical Movement: \((bio["headMovement"] as? [String: Any])?["verticalMovement"] ?? 0) cm
            """
        }
        
        // Hip-Shoulder Separation (X-Factor)
        if (confidences["hipShoulderSeparation"] ?? 1.0) >= 0.7 {
            promptBuilder += """
            
            Hip-Shoulder Separation/X-Factor (Confidence: \(String(format: "%.1f", confidences["hipShoulderSeparation"] ?? 1.0))):
            - At Top of Backswing: \((bio["xFactor"] as? [String: Any])?["atTop"] ?? 0)°
            - At Impact: \((bio["xFactor"] as? [String: Any])?["atImpact"] ?? 0)°
            - Hip Open at Impact: \((bio["hipRotation"] as? [String: Any])?["atImpact"] ?? 0)° (relative to setup)
            """
        }
        
        // Kinematic Sequence (KEY METRIC)
        if let kinematicSeq = bio["kinematicSequence"] as? [String: Any], (confidences["kinematicSequence"] ?? 1.0) >= 0.7 {
            promptBuilder += """
            
            Kinematic Sequence - Peak Angular Velocity Order (Confidence: \(String(format: "%.1f", confidences["kinematicSequence"] ?? 1.0))):
            - Hips: \(kinematicSeq["hipsTime"] ?? 0) ms from start of downswing
            - Torso: \(kinematicSeq["torsoTime"] ?? 0) ms
            - Arms: \(kinematicSeq["armsTime"] ?? 0) ms  
            - Hands: \(kinematicSeq["handsTime"] ?? 0) ms
            - Sequence Order: \(kinematicSeq["sequenceOrder"] ?? "unknown")
            """
        }
        
        // Spine Tilt/Early Extension
        if (confidences["spineTilt"] ?? 1.0) >= 0.7 {
            promptBuilder += """
            
            Spine Angle Analysis (Confidence: \(String(format: "%.1f", confidences["spineTilt"] ?? 1.0))):
            - Setup Spine Tilt: \((bio["spineAngle"] as? [String: Any])?["atSetup"] ?? 0)°
            - Impact Spine Tilt: \((bio["spineAngle"] as? [String: Any])?["atImpact"] ?? 0)°
            - Tilt Change: \((bio["spineAngle"] as? [String: Any])?["tiltChange"] ?? 0)° (positive = early extension/standing up)
            """
        }
        
        // Hand Path and Shallowing
        if (confidences["handPath"] ?? 1.0) >= 0.7 {
            promptBuilder += """
            
            Hand Path Analysis (Confidence: \(String(format: "%.1f", confidences["handPath"] ?? 1.0))):
            - Path Depth: \((bio["handPath"] as? [String: Any])?["depth"] ?? 0) (0-1 scale, deeper = better)
            - Shallowing Angle: \((bio["handPath"] as? [String: Any])?["shallowingAngle"] ?? 0)° (negative = shallowing)
            - Path Consistency: \((bio["handPath"] as? [String: Any])?["consistency"] ?? 0) (0-1 scale)
            """
        }
        
        // Weight Shift (Center of Mass)
        if (confidences["weightShift"] ?? 1.0) >= 0.7 {
            promptBuilder += """
            
            Weight Shift/Center of Mass (Confidence: \(String(format: "%.1f", confidences["weightShift"] ?? 1.0))):
            - Backswing Shift: \((bio["weightShift"] as? [String: Any])?["backswing"] ?? 0) cm toward trail side
            - Impact Position: \((bio["weightShift"] as? [String: Any])?["impact"] ?? 0) cm toward target
            - Finish Balance: \((bio["weightShift"] as? [String: Any])?["finishBalance"] ?? 0) (0-1 scale, over lead foot)
            """
        }
        
        // Lower confidence metrics (mention briefly)
        var lowConfidenceMetrics: [String] = []
        if (confidences["elbowAnalysis"] ?? 0.0) < 0.7 && (confidences["elbowAnalysis"] ?? 0.0) > 0.0 {
            lowConfidenceMetrics.append("elbow positions")
        }
        if (confidences["kneeAction"] ?? 0.0) < 0.7 && (confidences["kneeAction"] ?? 0.0) > 0.0 {
            lowConfidenceMetrics.append("knee flex patterns") 
        }
        
        if !lowConfidenceMetrics.isEmpty {
            promptBuilder += """
            
            LOW-CONFIDENCE METRICS (mention only if critical): \(lowConfidenceMetrics.joined(separator: ", "))
            """
        }
        
        // Add progression analysis if available
        if let progression = swingData["progressionData"] as? [String: Any],
           let trends = progression["trends"] as? [String: Any] {
            promptBuilder += """
            
            FRAME-BY-FRAME PROGRESSION ANALYSIS:
            Movement Trends Throughout Swing:
            - Hip Rotation Trend: \(trends["hipRotationTrend"] ?? "unknown")
            - Shoulder Rotation Trend: \(trends["shoulderRotationTrend"] ?? "unknown")  
            - Sequence Order: \(trends["sequenceOrder"] ?? "unknown")
            - Frames Analyzed: \(trends["totalFramesAnalyzed"] ?? 0)
            
            Use this to identify timing issues and coordination problems between body parts.
            """
        }
        
        promptBuilder += """
        
        Raw Pose Data: \((swingData["poseFrameData"] as? [Any])?.count ?? 0) frames with keypoint coordinates
        """
    }
    
    promptBuilder += """
    
    Please provide analysis in this exact JSON format (no additional text):
    {
        "feedback": "Overall swing assessment in 2-3 sentences focusing on impact positions and sequence",
        "improvements": ["Improvement 1 with drill: [specific 15-word drill]", "Improvement 2 with drill: [specific 15-word drill]", "Improvement 3 with drill: [specific 15-word drill]"],
        "technicalTips": ["Impact-focused tip 1", "Sequence-focused tip 2", "Setup/backswing tip 3"],
        "searchKeywords": ["keyword1", "keyword2", "keyword3"]
    }
    
    ANALYSIS FOCUS:
    1. Impact alignments first: head stability, spine angle, hip rotation, weight forward
    2. Kinematic sequence timing: hips → torso → arms → hands
    3. Transition quality: hand path shallowing, X-factor usage
    4. Rank improvements by ball-flight impact (impact issues first, then sequence, then setup)
    5. Each improvement MUST include a specific drill in the same line
    
    IGNORE low-confidence metrics completely. Focus on what video analysis can reliably measure.
    """
    
    return promptBuilder
}
