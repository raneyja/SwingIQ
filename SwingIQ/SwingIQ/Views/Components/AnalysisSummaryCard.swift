//
//  AnalysisSummaryCard.swift
//  SwingIQ
//
//  Analysis summary card component
//

import SwiftUI

struct AnalysisSummaryCard: View {
    let overallGrade: String
    let strengthText: String
    let focusAreaText: String
    let onTap: () -> Void
    
    init(overallGrade: String = "B+", 
         strengthText: String = "Excellent swing path consistency", 
         focusAreaText: String = "Increase club head speed",
         onTap: @escaping () -> Void = {}) {
        self.overallGrade = overallGrade
        self.strengthText = strengthText
        self.focusAreaText = focusAreaText
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    Text("Analysis Summary")
                        .font(.title2)
                        .foregroundColor(.primary)
                    Spacer()
                    
                    // Overall Grade
                    Text(overallGrade)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.green.opacity(0.1)))
                        .overlay(
                            Circle().stroke(Color.green, lineWidth: 2)
                        )
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Strength: \(strengthText)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Focus Area: \(focusAreaText)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
