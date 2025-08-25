//
//  HomeView.swift
//  SwingIQ
//
//  Redesigned to match Sportsbox AI aesthetic - Simplified & CTA-focused
//

import SwiftUI

struct HomeView: View {
    // Simplified state - focus on CTA rather than analytics
    @State private var swingScore = 76
    @State private var practiceStreak = 7
    @State private var lastUpload = "1 day ago"
    @State private var chestTurn = 76.0
    @State private var pelvisSway = 1.2
    
    // Navigation state
    @State private var showingCameraView = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 35) {
                // Hero Section - Focused on CTA
                heroSection
                
                // Minimal Stats Section
                swingGlanceSection
                
                // Simple Next Steps
                nextStepsSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
        .background(Color.white)
        .ignoresSafeArea(.container, edges: .top)
        .sheet(isPresented: $showingCameraView) {
            WorkingCameraView(onNavigateToHome: {
                showingCameraView = false // Close the sheet to return to home
            })
        }
    }
    
    // MARK: - Hero Section (CTA Focused)
    private var heroSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("SWING ANALYSIS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(spacing: 40) {
                // Large Title & Subtitle
                VStack(spacing: 16) {
                    Text("Analyze Your Swing")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("Measure body movement and swing characteristics with a single upload")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 20)
                }
                
                // 3D Figure with Dark Floating Cards
                ZStack {
                    // Background circle for emphasis
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.03), Color.purple.opacity(0.01)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 280, height: 280)
                    
                    // Path-Based Golf Figurine
                    ImageGolferFigurine()
                        .frame(width: 406, height: 569)
                        .offset(y: -10)
                    
                    // Dark Floating Cards (matching screenshot)
                    darkFloatingCards
                }
                .frame(height: 380)
                .padding(.bottom, -66)
                
                // Large Purple CTA Button
                Button(action: {
                    showingCameraView = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Get Swing Score")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.25, blue: 0.95),
                                Color(red: 0.55, green: 0.35, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: Color(red: 0.45, green: 0.25, blue: 0.95).opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 20)
            }
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.purple.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
                .padding(.top, 40)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Dark Floating Cards (matching screenshot)
    private var darkFloatingCards: some View {
        ZStack {
            // Chest Turn Card (Left)
            DarkFloatingCard(
                title: "Chest Turn",
                value: "\(Int(chestTurn))°"
            )
            .offset(x: -100, y: -40)
            
            // Pelvis Sway Card (Right)
            DarkFloatingCard(
                title: "Pelvis Sway",
                value: String(format: "%.1f in", pelvisSway)
            )
            .offset(x: 100, y: 60)
        }
    }
    
    // MARK: - Minimal Stats Section
    private var swingGlanceSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("PERFORMANCE OVERVIEW")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(alignment: .leading, spacing: 25) {
                Text("Your Swing at a Glance")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                // Enhanced horizontal layout with cards
                HStack(spacing: 16) {
                    // Swing Score
                    StatCard(
                        value: "76",
                        title: "Swing Score",
                        isHighlighted: true
                    )
                    
                    // Practice Streak
                    StatCard(
                        value: "7 days",
                        title: "Practice Streak",
                        isHighlighted: false
                    )
                    
                    // Last Upload
                    StatCard(
                        value: "1 day ago",
                        title: "Last Upload",
                        isHighlighted: false
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.blue.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Simple Next Steps
    private var nextStepsSection: some View {
        VStack(spacing: 0) {
            // Section Header with boundary
            VStack(spacing: 20) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                
                Text("IMPROVEMENT ROADMAP")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green.opacity(0.8))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.green.opacity(0.05))
                    )
            }
            .padding(.bottom, 30)
            
            VStack(alignment: .leading, spacing: 25) {
                Text("Next Steps")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 16) {
                    EnhancedActionItem(
                        icon: "🥅",
                        title: "Focus:",
                        description: "Shallow out your downswing",
                        priority: .high
                    )
                    
                    EnhancedActionItem(
                        icon: "🎥",
                        title: "Workshop:",
                        description: "Watch \"Creating More Hip Turn\"",
                        priority: .medium
                    )
                    
                    EnhancedActionItem(
                        icon: "📅",
                        title: "Next Tee Time:",
                        description: "Add from Calendar",
                        priority: .low
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            
            // Section footer boundary
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.green.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Dark Floating Card Component (matching screenshot)
struct DarkFloatingCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2)) // Yellow/orange like screenshot
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2)) // Dark gray
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let value: String
    let title: String
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isHighlighted ? .purple : .black)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isHighlighted ? 
                            LinearGradient(colors: [.purple.opacity(0.3), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: isHighlighted ? Color.purple.opacity(0.1) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Priority Enum
enum ActionPriority {
    case high, medium, low
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "clock.circle.fill"
        case .low: return "info.circle.fill"
        }
    }
}

// MARK: - Enhanced Action Item Component
struct EnhancedActionItem: View {
    let icon: String
    let title: String
    let description: String
    let priority: ActionPriority
    
    var body: some View {
        HStack(spacing: 16) {
            // Main icon
            Text(icon)
                .font(.system(size: 24))
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Priority indicator
                    Image(systemName: priority.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(priority.color)
                }
            }
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Skeletal Golf Figure Component
struct SkeletalGolfFigure: View {
    var body: some View {
        ZStack {
            // Main body skeleton
            Path { path in
                // Head
                path.addEllipse(in: CGRect(x: 85, y: 10, width: 25, height: 25))
                
                // Spine line
                path.move(to: CGPoint(x: 97, y: 35))
                path.addLine(to: CGPoint(x: 85, y: 130))
                
                // Left arm - extended for golf swing
                path.move(to: CGPoint(x: 97, y: 50))
                path.addLine(to: CGPoint(x: 60, y: 40))
                path.addLine(to: CGPoint(x: 35, y: 60))
                
                // Right arm - extended for golf swing
                path.move(to: CGPoint(x: 97, y: 50))
                path.addLine(to: CGPoint(x: 130, y: 45))
                path.addLine(to: CGPoint(x: 150, y: 70))
                
                // Left leg
                path.move(to: CGPoint(x: 85, y: 130))
                path.addLine(to: CGPoint(x: 75, y: 170))
                path.addLine(to: CGPoint(x: 70, y: 200))
                
                // Right leg  
                path.move(to: CGPoint(x: 85, y: 130))
                path.addLine(to: CGPoint(x: 95, y: 170))
                path.addLine(to: CGPoint(x: 100, y: 200))
                
                // Shoulders
                path.move(to: CGPoint(x: 80, y: 50))
                path.addLine(to: CGPoint(x: 114, y: 50))
                
                // Hips
                path.move(to: CGPoint(x: 75, y: 110))
                path.addLine(to: CGPoint(x: 95, y: 110))
            }
            .stroke(Color.gray.opacity(0.7), lineWidth: 3)
            
            // Joint circles
            Group {
                // Head
                Circle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 25, height: 25)
                    .position(x: 97, y: 22)
                
                // Shoulders
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .position(x: 80, y: 50)
                
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .position(x: 114, y: 50)
                
                // Elbows
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .position(x: 60, y: 40)
                
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .position(x: 130, y: 45)
                
                // Wrists
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 5, height: 5)
                    .position(x: 35, y: 60)
                
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 5, height: 5)
                    .position(x: 150, y: 70)
                
                // Hips
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .position(x: 75, y: 110)
                
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .position(x: 95, y: 110)
                
                // Knees
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .position(x: 75, y: 170)
                
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .position(x: 95, y: 170)
                
                // Feet
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 5, height: 5)
                    .position(x: 70, y: 200)
                
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 5, height: 5)
                    .position(x: 100, y: 200)
            }
            
            // Golf club
            Path { path in
                // Club shaft
                path.move(to: CGPoint(x: 35, y: 60))
                path.addLine(to: CGPoint(x: 10, y: 30))
                
                // Club head
                path.addEllipse(in: CGRect(x: 5, y: 25, width: 10, height: 10))
            }
            .stroke(Color.gray.opacity(0.8), lineWidth: 2)
            .fill(Color.gray.opacity(0.3))
            
            // Analytics markers (red dots like in your image)
            Group {
                // Chest turn marker
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .position(x: 97, y: 65)
                
                // Pelvis sway marker
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .position(x: 85, y: 110)
                
                // Motion line for chest turn
                Path { path in
                    path.move(to: CGPoint(x: 97, y: 65))
                    path.addCurve(to: CGPoint(x: 115, y: 55),
                                control1: CGPoint(x: 105, y: 60),
                                control2: CGPoint(x: 110, y: 57))
                }
                .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }
        }
        .frame(width: 180, height: 220)
    }
}

#Preview {
    HomeView()
}
