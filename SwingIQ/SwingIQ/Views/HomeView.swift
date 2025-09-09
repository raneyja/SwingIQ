//
//  HomeView.swift
//  SwingIQ
//
//  Redesigned to match Sportsbox AI aesthetic - Simplified & CTA-focused
//

import SwiftUI

struct HomeView: View {
    // State for demo data shown in floating cards
    @State private var chestTurn = 76.0
    @State private var pelvisSway = 1.2
    
    // Navigation state
    @State private var showingCameraView = false
    
    var body: some View {
        VStack(spacing: 35) {
            heroSection
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
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
                
                Text("SwingIQ")
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
                    colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                    ))
                    .frame(width: 420, height: 420)
                    
                    // Unified Golf Figurine
                    UnifiedGolferFigurine(
                        style: .image,
                        isAnimated: false,
                        size: CGSize(width: 406, height: 569)
                    )
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
                .padding(.top, 50)
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



#Preview {
    HomeView()
}
