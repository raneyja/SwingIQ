//
//  MetricDetailCard.swift
//  SwingIQ
//
//  Metric detail card component for displaying swing metrics
//

import SwiftUI

struct MetricDetailCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: String?
    let color: Color
    let targetRange: String?
    let status: String?
    let description: String?
    let isClickable: Bool
    
    init(title: String, value: String, unit: String = "", trend: String? = nil, color: Color = .blue, targetRange: String? = nil, status: String? = nil, description: String? = nil, isClickable: Bool = false) {
        self.title = title
        self.value = value
        self.unit = unit
        self.trend = trend
        self.color = color
        self.targetRange = targetRange
        self.status = status
        self.description = description
        self.isClickable = isClickable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(trendColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(trendColor.opacity(0.1))
                        .cornerRadius(8)
                }
                if let status = status {
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .offset(y: -2)
                }
            }
            
            if let targetRange = targetRange {
                Text("Target: \(targetRange)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if isClickable {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.05))
                .stroke(color.opacity(0.3), lineWidth: isClickable ? 2 : 1)
        )
    }
    
    private var trendColor: Color {
        guard let trend = trend else { return .gray }
        if trend.contains("↑") {
            return .green
        } else if trend.contains("↓") {
            return .red
        } else {
            return .gray
        }
    }
    
    private var statusColor: Color {
        guard let status = status else { return .gray }
        if status.lowercased().contains("good") || status.lowercased().contains("excellent") {
            return .green
        } else if status.lowercased().contains("poor") || status.lowercased().contains("needs") {
            return .red
        } else if status.lowercased().contains("fair") || status.lowercased().contains("average") {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricDetailCard(
            title: "Club Speed",
            value: "87.5",
            unit: "mph",
            trend: "↑ 2.3%",
            color: .blue
        )
        
        MetricDetailCard(
            title: "Ball Speed",
            value: "128.2",
            unit: "mph",
            trend: "↓ 1.1%",
            color: .green
        )
        
        MetricDetailCard(
            title: "Tempo",
            value: "3:1",
            color: .orange
        )
    }
    .padding()
}
