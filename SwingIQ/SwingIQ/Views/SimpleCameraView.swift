//
//  SimpleCameraView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import AVFoundation

struct SimpleCameraView: View {
    @StateObject private var cameraService = CameraService()
    @State private var isRecording = false
    
    var body: some View {
        ZStack {
            // Background color to test if view loads
            Color.black.ignoresSafeArea()
            
            VStack {
                // Debug info
                Text("Camera Service Status")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                
                Text("Authorized: \(cameraService.isCameraAuthorized ? "Yes" : "No")")
                    .foregroundColor(.white)
                    .padding()
                
                // Camera preview
                if cameraService.isCameraAuthorized {
                    CameraPreview(session: cameraService.session)
                        .frame(height: 400)
                        .cornerRadius(12)
                        .onAppear {
                            print("📱 Starting camera session...")
                            cameraService.startSession()
                        }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Button("Request Permission") {
                            print("📱 Requesting camera permission...")
                            cameraService.checkCameraPermission()
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .frame(height: 400)
                }
                
                Spacer()
                
                // Simple record button
                Button(action: {
                    if isRecording {
                        print("📱 Stopping recording...")
                        cameraService.stopRecording()
                        isRecording = false
                    } else {
                        print("📱 Starting recording...")
                        cameraService.startRecording()
                        isRecording = true
                    }
                }) {
                    Circle()
                        .fill(isRecording ? Color.red : Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                }
                .disabled(!cameraService.isCameraAuthorized)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("📱 SimpleCameraView appeared")
            cameraService.checkCameraPermission()
        }
        .alert("Camera Error", isPresented: $cameraService.showAlert) {
            Button("OK") { }
        } message: {
            Text(cameraService.alertError.message)
        }
    }
}

struct SimpleCameraView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleCameraView()
    }
}
