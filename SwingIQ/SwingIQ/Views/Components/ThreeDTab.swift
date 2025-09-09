//
//  ThreeDTab.swift
//  SwingIQ
//
//  3D visualization tab component for MediaPipe testing
//

import SwiftUI

struct ThreeDTab: View {
    var body: some View {
        VStack {
            EmptyThreeDView()
        }
    }
}

struct EmptyThreeDView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Pose Data")
                .font(.headline)
            
            Text("Analyze an image or use live camera to see 3D pose visualization.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
