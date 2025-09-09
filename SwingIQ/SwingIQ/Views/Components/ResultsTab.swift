//
//  ResultsTab.swift
//  SwingIQ
//
//  Results tab component for MediaPipe testing
//

import SwiftUI

struct ResultsTab: View {
    @Binding var analysisResults: [TestAnalysisResult]
    
    var body: some View {
        VStack {
            if analysisResults.isEmpty {
                EmptyResultsView()
            } else {
                ResultsListView(analysisResults: $analysisResults)
            }
        }
    }
}

struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Analysis Results")
                .font(.headline)
            
            Text("Capture images or record videos to see analysis results here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ResultsListView: View {
    @Binding var analysisResults: [TestAnalysisResult]
    
    var body: some View {
        List {
            ForEach(analysisResults) { result in
                ResultRow(result: result)
            }
            .onDelete(perform: deleteResults)
        }
        .navigationTitle("Analysis Results")
    }
    
    private func deleteResults(offsets: IndexSet) {
        analysisResults.remove(atOffsets: offsets)
    }
}

struct ResultRow: View {
    let result: TestAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Analysis")
                    .font(.headline)
                
                Spacer()
                
                Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Keypoints: \(result.keypointCount)")
                    Text("Confidence: \(String(format: "%.1f%%", result.confidence * 100))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Phase: Analysis")
                    Text("Score: \(String(format: "%.1f", result.score))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
