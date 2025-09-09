//
//  ImageAnalysisTabStub.swift
//  SwingIQ
//
//  Stub replacement for ImageAnalysisTab after MediaPipe removal
//

import SwiftUI

struct ImageAnalysisTab: View {
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var isAnalyzing: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Image analysis is unavailable in this build.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Text("MediaPipe functionality has been removed")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}
