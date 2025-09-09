//
//  RecommendedContentCard.swift
//  SwingIQ
//
//  Card component for displaying recommended content and training materials
//

import SwiftUI

enum RecommendedContentType: String, CaseIterable {
    case video = "Video"
    case article = "Article"  
    case drill = "Drill"
    case tip = "Tip"
    
    var icon: String {
        switch self {
        case .video: return "play.rectangle"
        case .article: return "doc.text"
        case .drill: return "figure.golf"
        case .tip: return "lightbulb"
        }
    }
    
    var color: Color {
        switch self {
        case .video: return .blue
        case .article: return .green
        case .drill: return .orange
        case .tip: return .purple
        }
    }
}

struct RecommendedContentCard: View {
    let title: String
    let description: String
    let type: RecommendedContentType
    let duration: String?
    
    init(title: String, description: String, type: RecommendedContentType, duration: String? = nil) {
        self.title = title
        self.description = description
        self.type = type
        self.duration = duration
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(.title3)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(type.color)
                
                Spacer()
                
                if let duration = duration {
                    Text(duration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.05))
                .stroke(type.color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        RecommendedContentCard(
            title: "Perfect Your Backswing",
            description: "Learn the fundamentals of a proper golf backswing with step-by-step guidance.",
            type: .video,
            duration: "8:45"
        )
        
        RecommendedContentCard(
            title: "Wall Drill for Better Tempo",
            description: "Practice this simple drill to improve your swing tempo and rhythm.",
            type: .drill,
            duration: "5 min"
        )
        
        RecommendedContentCard(
            title: "Reading Your Ball Flight",
            description: "Understand what your ball flight tells you about your swing mechanics.",
            type: .article
        )
    }
    .padding()
}
