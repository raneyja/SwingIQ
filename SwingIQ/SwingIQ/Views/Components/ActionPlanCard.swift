//
//  ActionPlanCard.swift
//  SwingIQ
//
//  Action plan card component for training recommendations
//

import SwiftUI

struct ActionPlanCard: View {
    let week: String
    let focus: String
    let description: String
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(week)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(focus)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? .blue.opacity(0.1) : .gray.opacity(0.05))
                .stroke(isActive ? .blue.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionPlanCard(
            week: "Week 1-2",
            focus: "Speed Training",
            description: "Focus on increasing clubhead speed with targeted drills",
            isActive: true
        )
        
        ActionPlanCard(
            week: "Week 3-4",
            focus: "Tempo Refinement",
            description: "Work on swing timing and rhythm consistency",
            isActive: false
        )
    }
    .padding()
}
