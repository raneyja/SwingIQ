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
                    if let analysis = video.analysisResult {
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
    private func analysisResultsSection(_ analysis: SwingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Results")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Score: \(analysis.overallScore, specifier: "%.1f")/10")
                    .font(.headline)
                
                if let summary = analysis.summary {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func recommendationsSection(_ analysis: SwingAnalysis) -> some View {
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
                        Text("\(index + 1). \(recommendation.category)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(recommendation.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.blue.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    @ViewBuilder
    private func metricsSection(_ analysis: SwingAnalysis) -> some View {
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
                    value: String(format: "%.1f", analysis.tempo ?? 0),
                    unit: "s",
                    color: .blue
                )
                
                MetricDetailCard(
                    title: "Balance",
                    value: String(format: "%.0f", (analysis.balance ?? 0) * 100),
                    unit: "%",
                    color: .green
                )
                
                MetricDetailCard(
                    title: "Swing Speed",
                    value: String(format: "%.0f", analysis.swingSpeed ?? 0),
                    unit: "mph",
                    color: .orange
                )
                
                MetricDetailCard(
                    title: "Path Deviation",
                    value: String(format: "%.1f", analysis.swingPathDeviation ?? 0),
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
    let sampleAnalysis = SwingAnalysis(
        id: UUID(),
        timestamp: Date(),
        overallScore: 7.5,
        tempo: 1.2,
        balance: 0.85,
        swingSpeed: 95.0,
        swingPathDeviation: 2.1,
        recommendations: [
            SwingRecommendation(category: "Speed", description: "Focus on hip rotation for more power", priority: .high),
            SwingRecommendation(category: "Balance", description: "Maintain better weight distribution", priority: .medium)
        ],
        summary: "Good overall swing with room for improvement in tempo and power generation."
    )
    
    let sampleVideo = ProcessingVideo(
        id: UUID(),
        url: URL(string: "https://example.com/video.mp4")!,
        name: "Practice Swing #1",
        status: .completed
    )
    // In a real implementation, you'd set the analysisResult
    
    VideoResultsView(video: sampleVideo)
}
