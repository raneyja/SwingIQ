//
//  ImprovementCard.swift
//  SwingIQ
//
//  Card component for displaying swing improvement recommendations
//

import SwiftUI

enum ImprovementPriority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case maintain = "Maintain"
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        case .maintain: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "questionmark.circle.fill"
        case .maintain: return "checkmark.circle.fill"
        }
    }
}

struct ImprovementCard: View {
    let priority: ImprovementPriority
    let title: String
    let description: String
    let actionable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: priority.icon)
                    .foregroundColor(priority.color)
                    .font(.title3)
                
                Text(priority.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(priority.color.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                if actionable {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
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
                .stroke(priority.color.opacity(0.3), lineWidth: actionable ? 2 : 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ImprovementCard(
            priority: .high,
            title: "Increase Club Head Speed",
            description: "Focus on rotation and timing to generate more speed through impact.",
            actionable: true
        )
        
        ImprovementCard(
            priority: .medium,
            title: "Improve Tempo",
            description: "Slow down backswing slightly for better rhythm and consistency.",
            actionable: true
        )
        
        ImprovementCard(
            priority: .maintain,
            title: "Maintain Swing Path",
            description: "Your plane is excellent - keep doing what you're doing.",
            actionable: false
        )
    }
    .padding()
}
