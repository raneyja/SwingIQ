//
//  ImprovementSection.swift
//  SwingIQ
//
//  Areas for improvement section with AI recommendations
//

import SwiftUI

struct ImprovementSection: View {
    let enhancedAnalysis: SwingAnalysis?
    let onNavigateToAnalysis: () -> Void
    let onNavigateToSpeed: () -> Void
    let onNavigateToTempo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas for Improvement")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let enhancedAnalysis = enhancedAnalysis {
                    aiRecommendationsView(enhancedAnalysis)
                } else {
                    fallbackImprovementsView
                }
            }
        }
    }
    
    // MARK: - AI Recommendations View
    
    private func aiRecommendationsView(_ analysis: SwingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI-Powered Recommendations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("Gemini")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            if let feedback = analysis.recommendations.first?.description {
                Text(feedback)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                NavigationButton(action: onNavigateToAnalysis) {
                    ImprovementCard(
                        priority: index == 0 ? .high : .medium,
                        title: "Improvement \(index + 1)",
                        description: recommendation.description,
                        actionable: true
                    )
                }
            }
        }
    }
    
    // MARK: - Fallback Improvements View
    
    private var fallbackImprovementsView: some View {
        Group {
            NavigationButton(action: onNavigateToSpeed) {
                ImprovementCard(
                    priority: .high,
                    title: "Increase Club Head Speed",
                    description: "Focus on rotation and timing to generate more speed",
                    actionable: true
                )
            }
            
            NavigationButton(action: onNavigateToTempo) {
                ImprovementCard(
                    priority: .medium,
                    title: "Improve Tempo",
                    description: "Slow down backswing slightly for better rhythm",
                    actionable: true
                )
            }
            
            ImprovementCard(
                priority: .maintain,
                title: "Maintain Swing Path",
                description: "Your plane is excellent - keep doing what you're doing",
                actionable: false
            )
        }
    }
}
