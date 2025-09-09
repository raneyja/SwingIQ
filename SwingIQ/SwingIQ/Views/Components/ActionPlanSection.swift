//
//  ActionPlanSection.swift
//  SwingIQ
//
//  Action plan section component
//

import SwiftUI

struct ActionPlanSection: View {
    let onNavigateToSpeed: () -> Void
    let onNavigateToTempo: () -> Void
    let onNavigateToBalance: () -> Void
    let onNavigateToProgress: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Action Plan")
                .font(.title3)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                NavigationButton(action: onNavigateToSpeed) {
                    ActionPlanCard(
                        week: "Week 1-2",
                        focus: "Speed Training",
                        description: "Focus on increasing clubhead speed with targeted drills",
                        isActive: true
                    )
                }
                
                NavigationButton(action: onNavigateToTempo) {
                    ActionPlanCard(
                        week: "Week 3-4",
                        focus: "Tempo Refinement",
                        description: "Work on swing timing and rhythm consistency",
                        isActive: false
                    )
                }
                
                NavigationButton(action: onNavigateToBalance) {
                    ActionPlanCard(
                        week: "Week 5-6",
                        focus: "Balance & Stability",
                        description: "Improve overall swing balance and control",
                        isActive: false
                    )
                }
                
                NavigationButton(action: onNavigateToProgress) {
                    ActionPlanCard(
                        week: "Ongoing",
                        focus: "Progress Tracking",
                        description: "Monitor improvements and adjust training focus",
                        isActive: false
                    )
                }
            }
        }
    }
}
