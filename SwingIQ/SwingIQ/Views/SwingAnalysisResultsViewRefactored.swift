//
//  SwingAnalysisResultsViewRefactored.swift
//  SwingIQ
//
//  Refactored video-centric swing analysis view with separated components
//

import SwiftUI
import AVKit
import SceneKit
import UIKit
import Combine

struct SwingAnalysisResultsViewRefactored: View {
    let video: ProcessingVideo
    @Environment(\.presentationMode) var presentationMode
    
    // Video layout tracking
    @State private var videoRect: CGRect = .zero
    @State private var currentTime: Double = 0
    
    // UI state
    @State private var isFullscreen = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isFullscreen {
                    fullscreenView(geometry: geometry)
                } else {
                    portraitView(geometry: geometry)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Portrait View (Main Layout)
    
    private func portraitView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Full screen video player
            videoPlayerView(height: geometry.size.height)
            
            VStack {
                // Header overlay
                headerView
                    .background(Color.black.opacity(0.7))
                
                Spacer()
                
                // Metrics panel overlay at bottom
                LiveMetricsPanel(
                    analysisResults: video.analysisResults,
                    enhancedAnalysis: nil // TODO: Convert EnhancedAnalysisResults to SwingAnalysis
                )
                .background(Color.black.opacity(0.8))
            }
        }
    }
    
    // MARK: - Fullscreen View
    
    private func fullscreenView(geometry: GeometryProxy) -> some View {
        // TODO: Implement fullscreen view
        EmptyView()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("Swing Analysis")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: shareAnalysis) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Video Player (Hero Element)
    
    private func videoPlayerView(height: CGFloat) -> some View {
        ZStack {
            // Unified Video Player with overlay
            UnifiedVideoPlayerComponent(
                url: video.url,
                configuration: .standard,
                onVideoRectChange: { rect in
                    self.videoRect = rect
                },
                onTimeChange: { time in
                    self.currentTime = time
                }
            ) {
                // MediaPipe overlay as part of the unified component
                if let poseData = video.poseData, !poseData.isEmpty {
                    MediaPipeOverlay(
                        poseData: poseData,
                        currentTime: currentTime,
                        viewSize: CGSize(width: UIScreen.main.bounds.width, height: height),
                        videoSize: video.videoSize,
                        isMirrored: false
                    )
                    .opacity(0.8)
                }
            }
            .frame(height: height)
            .clipped()
            
            // Enhanced live data display in top right
            VStack {
                HStack {
                    Spacer()
                    EnhancedLiveDataPanel(
                        poseData: video.poseData,
                        currentTime: currentTime
                    )
                    .padding(.top, 20)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func shareAnalysis() {
        // TODO: Implement share functionality
    }
}
