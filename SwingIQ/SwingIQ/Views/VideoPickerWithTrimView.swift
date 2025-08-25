//
//  VideoPickerWithTrimView.swift
//  SwingIQ
//
//  Created by Amp on 7/23/25.
//

import SwiftUI
import UIKit

struct VideoPickerWithTrimView: UIViewControllerRepresentable {
    let onVideoSelected: (URL) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.allowsEditing = true // Enable native iOS trimming
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerWithTrimView

        init(_ parent: VideoPickerWithTrimView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📹 Video picker finished with info keys: \(info.keys)")
            
            // Try to get the edited video URL first, fallback to original
            var videoURL: URL?
            
            if let editedURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                print("📹 Found video URL: \(editedURL)")
                videoURL = editedURL
            }
            
            if let url = videoURL {
                print("📹 VideoPickerWithTrimView: Calling onVideoSelected with URL: \(url)")
                parent.onVideoSelected(url)
                print("📹 VideoPickerWithTrimView: onVideoSelected callback completed")
            } else {
                print("📹 VideoPickerWithTrimView: No video URL found in picker info")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📹 Video picker cancelled")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - SwiftUI Wrapper for Easy Integration

struct VideoPickerWithTrimButton: View {
    let onVideoSelected: (URL) -> Void
    @State private var showingVideoPicker = false
    
    var body: some View {
        Button(action: {
            showingVideoPicker = true
        }) {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "folder.badge.plus")
                        .font(.title2)
                        .foregroundColor(.white)
                )
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerWithTrimView { url in
                print("📹 VideoPickerWithTrimButton received video URL: \(url)")
                onVideoSelected(url)
            }
        }
    }
}
