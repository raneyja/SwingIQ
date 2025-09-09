//
//  RecommendedContentSection.swift
//  SwingIQ
//
//  Recommended content section with YouTube integration
//

import SwiftUI

struct RecommendedContentSection: View {
    let enhancedAnalysis: SwingAnalysis?
    let onNavigateToSpeed: () -> Void
    let onNavigateToTempo: () -> Void
    let onNavigateToAnalysis: () -> Void
    let onNavigateToProgress: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Content")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if enhancedAnalysis != nil {
                    // TODO: Convert SwingAnalysis.recommendations to GolfYouTubeRecommendation format
                    fallbackRecommendationsView
                } else {
                    fallbackRecommendationsView
                }
            }
        }
    }
    
    // MARK: - Fallback Recommendations View
    
    private var fallbackRecommendationsView: some View {
        Group {
            NavigationButton(action: onNavigateToSpeed) {
                RecommendedContentCard(
                    title: "Speed Training Drills",
                    description: "5 exercises to increase clubhead speed",
                    type: .video,
                    duration: "12 min"
                )
            }
            
            NavigationButton(action: onNavigateToTempo) {
                RecommendedContentCard(
                    title: "Tempo Improvement",
                    description: "Perfect your swing timing",
                    type: .video,
                    duration: "8 min"
                )
            }
            
            NavigationButton(action: onNavigateToAnalysis) {
                RecommendedContentCard(
                    title: "Compare to Tour Pros",
                    description: "See how your metrics stack up",
                    type: .article
                )
            }
            
            NavigationButton(action: onNavigateToProgress) {
                RecommendedContentCard(
                    title: "Track Progress",
                    description: "Monitor improvement over time",
                    type: .tip
                )
            }
        }
    }
}
