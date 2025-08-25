//
//  ProcessingQueueView.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI

struct ProcessingQueueView: View {
    @EnvironmentObject var videoProcessor: VideoProcessorService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if videoProcessor.processingVideos.isEmpty && videoProcessor.completedVideos.isEmpty {
                    emptyQueueView
                } else {
                    queueList
                }
            }
            .navigationTitle("Processing Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !videoProcessor.completedVideos.isEmpty {
                        Button("Clear Completed") {
                            videoProcessor.clearCompleted()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Queue View
    
    private var emptyQueueView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Videos Processing")
                .font(.headline)
            
            Text("Videos you record or upload will appear here while being analyzed.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Queue List
    
    private var queueList: some View {
        List {
            // Processing videos section
            if !videoProcessor.processingVideos.isEmpty {
                Section("Processing") {
                    ForEach(videoProcessor.processingVideos) { video in
                        ProcessingVideoRow(video: video)
                            .environmentObject(videoProcessor)
                    }
                }
            }
            
            // Completed videos section
            if !videoProcessor.completedVideos.isEmpty {
                Section("Completed") {
                    ForEach(videoProcessor.completedVideos) { video in
                        CompletedVideoRow(video: video)
                            .environmentObject(videoProcessor)
                    }
                }
            }
        }
    }
}

// MARK: - Processing Video Row

struct ProcessingVideoRow: View {
    let video: ProcessingVideo
    @EnvironmentObject var videoProcessor: VideoProcessorService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Video name and status
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(video.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if video.status == .queued || video.status == .processing {
                    Button("Cancel") {
                        videoProcessor.cancelProcessing(videoId: video.id)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Progress bar and time estimate
            if video.status == .processing {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: video.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("\(Int(video.progress * 100))% complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let timeRemaining = video.estimatedTimeRemaining {
                            Text("~\(Int(timeRemaining))s remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Date added
            Text("Added: \(video.dateAdded.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch video.status {
        case .queued:
            return "clock"
        case .processing:
            return "gearshape.2"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        case .cancelled:
            return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch video.status {
        case .queued:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Completed Video Row

struct CompletedVideoRow: View {
    let video: ProcessingVideo
    @EnvironmentObject var videoProcessor: VideoProcessorService
    
    var body: some View {
        NavigationLink(destination: VideoResultsView(video: video)) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if video.status == .completed {
                        if let results = video.analysisResults {
                            Text("Score: \(Int(results.overallScore))/100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(video.status.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if video.status == .failed {
                    Button("Retry") {
                        videoProcessor.retryProcessing(videoId: video.id)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var statusIcon: String {
        switch video.status {
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        default:
            return "circle"
        }
    }
    
    private var statusColor: Color {
        switch video.status {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        default:
            return .gray
        }
    }
}

// MARK: - Preview

struct ProcessingQueueView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingQueueView()
            .environmentObject(VideoProcessorService())
    }
}
