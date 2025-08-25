//
//  AIAnalysisServiceProgressionTests.swift
//  SwingIQTests
//
//  Created by Amp on 8/19/25.
//

import XCTest
@testable import SwingIQ

final class AIAnalysisServiceProgressionTests: XCTestCase {
    
    private let service = AIAnalysisService()
    
    // Helper to create synthetic frame data
    private func makeFrame(num: Int, ts: TimeInterval, hipNil: Bool = false) -> PoseFrameData {
        let zero = CGPoint.zero
        var pts = Array(repeating: zero, count: 17)
        
        // Populate keypoints for basic biomechanical calculations
        pts[0] = CGPoint(x: 1.5, y: 0.5)  // nose
        pts[1] = CGPoint(x: 1, y: 1)      // left shoulder
        pts[2] = CGPoint(x: 2, y: 1)      // right shoulder
        pts[3] = CGPoint(x: 1, y: 2)      // left elbow
        pts[4] = CGPoint(x: 2, y: 2)      // right elbow
        pts[5] = CGPoint(x: 1, y: 3)      // left wrist
        pts[6] = CGPoint(x: 2, y: 3)      // right wrist
        
        if !hipNil {
            pts[7] = CGPoint(x: 1, y: 4)  // left hip
            pts[8] = CGPoint(x: 2, y: 4)  // right hip
        }
        
        pts[9] = CGPoint(x: 1, y: 5)      // left knee
        pts[10] = CGPoint(x: 2, y: 5)     // right knee
        pts[11] = CGPoint(x: 1, y: 6)     // left ankle
        pts[12] = CGPoint(x: 2, y: 6)     // right ankle
        
        return PoseFrameData(
            frameNumber: num,
            timestamp: ts,
            keypoints: pts,
            confidence: Array(repeating: 0.9, count: 17)
        )
    }
    
    func testNilHipAngleNotInserted() {
        let frames = [
            makeFrame(num: 0, ts: 0, hipNil: true),
            makeFrame(num: 1, ts: 0.033)
        ]
        
        let progression = service.performTestableProgression(frames)
        let frameData = progression["frames"] as! [[String: Any]]
        let firstFrameBio = frameData.first!["b"] as! [String: Any]
        
        XCTAssertNil(firstFrameBio["hipAngle"], "Hip angle should be absent when keypoints are missing")
    }
    
    func testFrameSamplingLimit() {
        let manyFrames = (0..<50).map { makeFrame(num: $0, ts: Double($0) * 0.033) }
        let sampled = service.sampleFramesForTesting(manyFrames, limit: 15)
        
        XCTAssertEqual(sampled.count, 15, "Sampling should cap at 15 frames")
        XCTAssertEqual(sampled.first?.frameNumber, 0, "First frame should be preserved")
        XCTAssertEqual(sampled.last?.frameNumber, 49, "Last frame should be preserved")
    }
    
    func testFPSComputation() {
        let frames = (0..<10).map { makeFrame(num: $0, ts: Double($0) * 0.05) }
        let progression = service.performTestableProgression(frames)
        let context = progression["context"] as! [String: Any]
        
        XCTAssertEqual(context["fps"] as! Double, 20.0, accuracy: 0.01, "FPS calculation incorrect")
        XCTAssertEqual(context["totalTime"] as! Double, 0.45, accuracy: 0.01, "Total time calculation incorrect")
    }
    
    func testTrendAnalysisWithValidData() {
        // Create frames with increasing hip angles
        let frames = (0..<9).map { i in
            let frame = makeFrame(num: i, ts: Double(i) * 0.033)
            return frame
        }
        
        let progression = service.performTestableProgression(frames)
        let trends = progression["trends"] as! [String: Any]
        
        XCTAssertNotNil(trends["hip"], "Hip trend should be calculated")
        XCTAssertTrue(trends["validFrames"] as! Int > 0, "Should have valid frames")
    }
    
    func testPayloadSizeLimit() {
        // Test with large number of frames to ensure we stay under token limit
        let largeFrameSet = (0..<240).map { makeFrame(num: $0, ts: Double($0) * 0.033) }
        let progression = service.performTestableProgression(largeFrameSet)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: progression)
            let sizeKB = Double(jsonData.count) / 1024.0
            
            XCTAssertLessThan(sizeKB, 25.0, "Progression payload should be under 25KB to leave room for other data")
            print("Progression payload size: \(sizeKB.rounded(toPlaces: 1))KB")
        } catch {
            XCTFail("Failed to serialize progression data: \(error)")
        }
    }
    
    func testEmptyFramesHandling() {
        let emptyFrames: [PoseFrameData] = []
        let progression = service.performTestableProgression(emptyFrames)
        
        XCTAssertTrue(progression.isEmpty, "Empty frames should return empty progression")
    }
    
    func testSingleFrameHandling() {
        let singleFrame = [makeFrame(num: 0, ts: 0)]
        let progression = service.performTestableProgression(singleFrame)
        
        XCTAssertTrue(progression.isEmpty, "Single frame should return empty progression")
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
