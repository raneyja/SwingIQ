//
//  SettingsView.swift
//  SwingIQ
//
//  Settings view component for MediaPipe testing
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var cameraService: CameraService
    @Binding var analysisResults: [TestAnalysisResult]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
            cameraSection
            analysisSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    

    
    private var cameraSection: some View {
        Section("Camera") {
            HStack {
                Text("Authorization")
                Spacer()
                Text(cameraService.isCameraAuthorized ? "Granted" : "Denied")
                    .foregroundColor(cameraService.isCameraAuthorized ? .green : .red)
            }
        }
    }
    
    private var analysisSection: some View {
        Section("Analysis") {
            HStack {
                Text("Total Results")
                Spacer()
                Text("\(analysisResults.count)")
                    .foregroundColor(.secondary)
            }
            
            Button("Clear All Results") {
                analysisResults.removeAll()
            }
            .foregroundColor(.red)
            .disabled(analysisResults.isEmpty)
        }
    }
}
