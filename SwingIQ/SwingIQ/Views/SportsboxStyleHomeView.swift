//
//  SportsboxStyleHomeView.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//  Redesigned to match Sportsbox AI aesthetic
//

import SwiftUI

struct SportsboxStyleHomeView: View {
    @State private var swingScore = 76
    @State private var practiceStreak = 7
    @State private var lastUpload = "1 day ago"
    @State private var chestTurn = 76.0
    @State private var pelvisSway = 1.2
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                // Hero Section - Sportsbox Style
                heroSection
                
                // Your Swing at a Glance - Dashboard Style
                swingGlanceSection
                
                // Next Steps - Actionable Recommendations
                nextStepsSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .background(Color.white)
        .ignoresSafeArea(.container, edges: .top)
    }
    
    // MARK: - Hero Section (Sportsbox Style)
    private var heroSection: some View {
        VStack(spacing: 36) {
            // Large Impact Title & Subtitle (Sportsbox Style)
            VStack(spacing: 16) {
                Text("Analyze Your Swing")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                
                Text("Measure body movement and swing characteristics with a single upload")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
            }
            
            // 3D Avatar with Floating Stats (Signature Sportsbox Feature)
            ZStack {
                // Central 3D Figure (Path-Based Golfer)
                VStack(spacing: 12) {
                    ImageGolferFigurine()
                    
                    Text("3D Swing Analysis")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(height: 300)
                
                // Floating Stat Cards (Sportsbox Signature)
                sportsboxFloatingCards
            }
            .frame(height: 360)
            
            // Primary CTA - Sportsbox Pill Style
            Button(action: {
                // TODO: Connect to MediaPipe + Gemini pipeline
                print("Get Swing Score - Processing video...")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "video.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Get Swing Score")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.36, blue: 0.96),
                            Color(red: 0.48, green: 0.23, blue: 0.93)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Sportsbox Floating Cards
    private var sportsboxFloatingCards: some View {
        ZStack {
            // Chest Turn Card (Left side, elevated)
            SportsboxFloatingCard(
                title: "Chest Turn",
                value: "\(Int(chestTurn))°",
                accentColor: Color(red: 0.55, green: 0.36, blue: 0.96)
            )
            .offset(x: -80, y: -30)
            .rotationEffect(.degrees(-5))
            
            // Pelvis Sway Card (Right side, lower)
            SportsboxFloatingCard(
                title: "Pelvis Sway",
                value: String(format: "%.1f in", pelvisSway),
                accentColor: Color(red: 0.48, green: 0.23, blue: 0.93)
            )
            .offset(x: 85, y: 50)
            .rotationEffect(.degrees(3))
        }
    }
    
    // MARK: - Your Swing at a Glance (Dashboard Style)
    private var swingGlanceSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your Swing at a Glance")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .tracking(-0.3)
            
            // Horizontal stat bar (Sportsbox dashboard style)
            HStack(spacing: 12) {
                // Swing Score
                SportsboxStatCard(
                    title: "Swing Score",
                    value: "\(swingScore)",
                    subtitle: "Overall rating",
                    isHighlighted: true
                )
                
                // Practice Streak
                SportsboxStatCard(
                    title: "Practice Streak",
                    value: "\(practiceStreak)",
                    subtitle: "days",
                    isHighlighted: false
                )
                
                // Last Upload
                SportsboxStatCard(
                    title: "Last Upload",
                    value: lastUpload,
                    subtitle: "Keep it up!",
                    isHighlighted: false
                )
            }
        }
    }
    
    // MARK: - Next Steps (Actionable Recommendations)
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Next Steps")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .tracking(-0.3)
            
            VStack(spacing: 14) {
                SportsboxActionItem(
                    icon: "🥅",
                    title: "Focus",
                    description: "Shallow out your downswing"
                )
                
                SportsboxActionItem(
                    icon: "🎥",
                    title: "Workshop",
                    description: "Watch \"Creating More Hip Turn\""
                )
                
                SportsboxActionItem(
                    icon: "📅",
                    title: "Next Tee Time",
                    description: "Add from Calendar"
                )
            }
        }
    }
}

// MARK: - Sportsbox Style Components

// MARK: - Sportsbox Floating Card Component
struct SportsboxFloatingCard: View {
    let title: String
    let value: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: accentColor.opacity(0.15), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Sportsbox Stat Card Component  
struct SportsboxStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(isHighlighted ? Color(red: 0.55, green: 0.36, blue: 0.96) : .black)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isHighlighted ? Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.1) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Sportsbox Action Item Component
struct SportsboxActionItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        Button(action: {
            // TODO: Handle action based on type
            print("Action tapped: \(title)")
        }) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 26))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SportsboxStyleHomeView()
}
