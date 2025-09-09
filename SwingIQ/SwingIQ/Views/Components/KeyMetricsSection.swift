//
//  KeyMetricsSection.swift
//  SwingIQ
//
//  Key metrics section component with navigation
//

import SwiftUI

struct KeyMetricsSection: View {
    let liveBalance: Double
    let liveTempo: Double
    let liveSwingPathDescription: String
    let onNavigateToBalance: () -> Void
    let onNavigateToTempo: () -> Void
    let onNavigateToSwingPath: () -> Void
    let onNavigateToHipShoulder: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Balance
                NavigationButton(action: onNavigateToBalance) {
                    MetricDetailCard(
                        title: "Balance",
                        value: "\(Int(liveBalance))",
                        unit: "%",
                        targetRange: "80-95",
                        status: balanceStatus(liveBalance),
                        description: "Good balance throughout the swing is key for consistency.",
                        isClickable: true
                    )
                }
                
                // Tempo
                NavigationButton(action: onNavigateToTempo) {
                    MetricDetailCard(
                        title: "Tempo",
                        value: String(format: "%.1f:1", liveTempo),
                        unit: "",
                        targetRange: "2.5:1 - 3.5:1",
                        status: tempoStatus(liveTempo),
                        description: getTempoDescription(liveTempo),
                        isClickable: true
                    )
                }
                
                // Swing Path
                NavigationButton(action: onNavigateToSwingPath) {
                    MetricDetailCard(
                        title: "Swing Path",
                        value: liveSwingPathDescription,
                        unit: "",
                        targetRange: "On Plane",
                        status: .excellent,
                        description: "Perfect plane consistency. Keep this up!",
                        isClickable: true
                    )
                }
                
                // Hip-Shoulder Separation
                NavigationButton(action: onNavigateToHipShoulder) {
                    MetricDetailCard(
                        title: "Hip-Shoulder Separation",
                        value: "32°",
                        unit: "",
                        targetRange: "30-45°",
                        status: .good,
                        description: "Good separation creating power. Room for slight improvement.",
                        isClickable: true
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func balanceStatus(_ balance: Double) -> String {
        switch balance {
        case 90...100: return "Excellent"
        case 80..<90: return "Good"
        case 70..<80: return "Okay"
        default: return "Needs Improvement"
        }
    }
    
    private func tempoStatus(_ tempo: Double) -> String {
        let difference = abs(tempo - 3.0)
        switch difference {
        case 0..<0.3: return "Excellent"
        case 0.3..<0.7: return "Good"
        case 0.7..<1.0: return "Okay"
        default: return "Needs Improvement"
        }
    }
    
    private func getTempoDescription(_ tempo: Double) -> String {
        if tempo > 3.5 {
            return "Slightly fast backswing. Try slowing down for better control."
        } else if tempo < 2.5 {
            return "Backswing could be faster for more power."
        } else {
            return "Great tempo! Perfect rhythm for consistency."
        }
    }
}

struct NavigationButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(PlainButtonStyle())
    }
}
