//
//  LiveCameraTab.swift
//  SwingIQ
//
//  Live camera tab component for MediaPipe testing
//

import SwiftUI

struct LiveCameraTab: View {
    @ObservedObject var cameraService: CameraService
    
    var body: some View {
        ZStack {
            if cameraService.isCameraAuthorized {
                cameraView
            } else {
                CameraPermissionView()
            }
        }
        .onAppear {
            if !cameraService.isCameraAuthorized {
                cameraService.checkCameraPermission()
            }
        }
    }
    
    // MARK: - Camera View
    
    private var cameraView: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
                .onAppear {
                    cameraService.startSession()
                }
                .onDisappear {
                    cameraService.stopSession()
                }
            
            // Pose overlay disabled (MediaPipe removed)
            // PoseOverlayView(keypoints: mediaPipeService.poseKeypoints)
            
            // Controls overlay
            VStack {
                Spacer()
                
                LiveCameraControls(cameraService: cameraService)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .padding()
            }
        }
    }
}

struct LiveCameraControls: View {
    @ObservedObject var cameraService: CameraService
    
    var body: some View {
        VStack(spacing: 16) {
            // Single status indicator (recording only)
            HStack {
                StatusIndicator(
                    title: "Recording",
                    isActive: cameraService.isRecording,
                    color: .red
                )
                Spacer()
            }
            
            // Camera controls
            HStack(spacing: 20) {
                Button(action: cameraService.flipCamera) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    if cameraService.isRecording {
                        cameraService.stopRecording()
                    } else {
                        cameraService.startRecording()
                    }
                }) {
                    Image(systemName: cameraService.isRecording ? "stop.circle" : "record.circle")
                        .font(.title)
                        .foregroundColor(cameraService.isRecording ? .red : .white)
                }
                
                Button(action: cameraService.capturePhoto) {
                    Image(systemName: "camera.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            // Metrics display
            // MediaPipe metrics disabled
            Text("Live pose analysis disabled")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatusIndicator: View {
    let title: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? color : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.headline)
            
            Text("Please enable camera access in Settings to test MediaPipe pose detection.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SwingMetricsDisplay: View {
    
    var body: some View {
        let metrics: SwingMetrics? = nil // TODO: Get metrics from SwingAnalysisCoordinator
        
        return VStack(spacing: 8) {
            Text("Swing Metrics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                MetricCard(
                    title: "Tempo", 
                    value: metrics?.tempoFormatted ?? "N/A", 
                    color: .orange
                )
                MetricCard(
                    title: "Balance", 
                    value: metrics?.balanceFormatted ?? "N/A", 
                    color: .purple
                )
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.3))
        .cornerRadius(8)
    }
}
