//
//  VideoResultsView.swift
//  SwingIQ
//
//  View for displaying completed video analysis results
//

import SwiftUI

struct VideoResultsView: View {
    let video: ProcessingVideo
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let analysis = video.analysisResults {
                        // Analysis Results Section
                        analysisResultsSection(analysis)
                        
                        // Recommendations Section
                        recommendationsSection(analysis)
                        
                        // Metrics Section
                        metricsSection(analysis)
                    } else {
                        // No analysis available
                        noAnalysisView
                    }
                }
                .padding()
            }
            .navigationTitle(video.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func analysisResultsSection(_ analysis: SwingAnalysisResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Results")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Score: \(analysis.overallScore, specifier: "%.1f")/10")
                    .font(.headline)
                
                Text("Current Phase: \(analysis.swingPhase)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func recommendationsSection(_ analysis: SwingAnalysisResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.title2)
                .fontWeight(.bold)
            
            if analysis.recommendations.isEmpty {
                Text("No specific recommendations available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(index + 1). \(recommendation)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(.blue.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    @ViewBuilder
    private func metricsSection(_ analysis: SwingAnalysisResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricDetailCard(
                    title: "Tempo",
                    value: String(format: "%.1f", analysis.tempo),
                    unit: "s",
                    color: .blue
                )
                
                MetricDetailCard(
                    title: "Balance",
                    value: String(format: "%.0f", analysis.balance * 100),
                    unit: "%",
                    color: .green
                )
                
                MetricDetailCard(
                    title: "Overall Score",
                    value: String(format: "%.1f", analysis.overallScore),
                    unit: "/10",
                    color: .orange
                )
                
                MetricDetailCard(
                    title: "Path Deviation",
                    value: String(format: "%.1f", analysis.swingPathDeviation),
                    unit: "°",
                    color: .purple
                )
            }
        }
    }
    
    private var noAnalysisView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No Analysis Available")
                .font(.title)
                .fontWeight(.bold)
            
            Text("The analysis for this video is not yet complete or encountered an error.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    // Create a sample ProcessingVideo with analysis for preview
    let sampleVideo = ProcessingVideo(
        id: UUID(),
        url: URL(string: "https://example.com/video.mp4")!,
        name: "Practice Swing #1",
        dateAdded: Date(),
        progress: 1.0,
        status: .completed,
        analysisResults: SwingAnalysisResults(
            tempo: 1.2,
            balance: 0.85,
            swingPathDeviation: 2.1,
            swingPhase: "Address",
            overallScore: 7.5,
            recommendations: ["Focus on hip rotation for more power", "Maintain better weight distribution"]
        )
    )
    
    VideoResultsView(video: sampleVideo)
}
