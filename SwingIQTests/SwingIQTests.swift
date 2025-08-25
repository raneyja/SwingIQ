//
//  SwingIQTests.swift
//  SwingIQTests
//
//  Created by Jonathan Raney on 7/18/25.
//

import Testing
import Foundation
import CoreGraphics
@testable import SwingIQ

struct SwingIQTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testVideoProcessorSafeArrayAccess() async throws {
        let processor = VideoProcessorService()
        
        // Test with empty keypoints - should not crash
        let emptyFrame = PoseFrameData(
            frameNumber: 0,
            timestamp: 0.0,
            keypoints: [],
            confidence: []
        )
        
        // Test with insufficient keypoints - should not crash
        let shortFrame = PoseFrameData(
            frameNumber: 1,
            timestamp: 0.1,
            keypoints: [CGPoint(x: 0.5, y: 0.5)], // Only 1 keypoint instead of 16+
            confidence: [0.9]
        )
        
        // Test analysis with problematic frames
        let frameData = [emptyFrame, shortFrame]
        
        // This should not crash due to our safety improvements
        let clubheadSpeed = processor.calculateClubheadSpeed(frameData)
        #expect(clubheadSpeed >= 0) // Should return 0 for insufficient data
    }
    
    @Test func testPoseFrameDataSafety() async throws {
        let processor = VideoProcessorService()
        
        // Create frame with valid keypoints
        let validKeypoints = Array(0..<20).map { i in
            CGPoint(x: Double(i) * 0.05, y: 0.5)
        }
        let validConfidence = Array(repeating: Float(0.9), count: 20)
        
        let validFrame = PoseFrameData(
            frameNumber: 0,
            timestamp: 0.0,
            keypoints: validKeypoints,
            confidence: validConfidence
        )
        
        // Test with valid data
        let clubheadSpeed = processor.calculateClubheadSpeed([validFrame, validFrame])
        #expect(clubheadSpeed >= 0)
    }
    
    @Test func testVideoProcessorInitialization() async throws {
        let processor = VideoProcessorService()
        
        // Verify initial state
        #expect(processor.processingVideos.isEmpty)
        #expect(processor.completedVideos.isEmpty)
        #expect(processor.isProcessing == false)
    }

}
