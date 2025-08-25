//
//  PathBasedGolferFigurine.swift
//  SwingIQ
//
//  Created by Amp on 8/8/25.
//  Realistic golfer figurine using custom path drawing
//

import SwiftUI



struct PathBasedGolferFigurine: View {
    var body: some View {
        ZStack {
            // Golf club positioned for follow-through swing
            golfClub
                .offset(x: 30, y: -60)
                .rotationEffect(.degrees(25))
            
            // Human-like golfer using recognizable shapes
            humanGolferFigure
        }
        .frame(width: 200, height: 280)
    }
    
    // MARK: - Human Golfer Figure
    
    private var humanGolferFigure: some View {
        ZStack {
            // Head
            Circle()
                .fill(golferGradient)
                .frame(width: 35, height: 35)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                .offset(x: 25, y: -110)
            
            // Neck
            RoundedRectangle(cornerRadius: 8)
                .fill(golferGradient)
                .frame(width: 16, height: 20)
                .offset(x: 22, y: -95)
            
            // Main torso - rotated for follow-through
            RoundedRectangle(cornerRadius: 25)
                .fill(golferGradient)
                .frame(width: 50, height: 80)
                .rotationEffect(.degrees(15))
                .shadow(color: .black.opacity(0.25), radius: 6, x: 3, y: 3)
                .offset(x: 15, y: -50)
            
            // Right arm (extended in follow-through)
            VStack(spacing: -5) {
                // Upper arm
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(25))
                    .offset(x: 45, y: -70)
                
                // Forearm
                RoundedRectangle(cornerRadius: 10)
                    .fill(golferGradient)
                    .frame(width: 15, height: 40)
                    .rotationEffect(.degrees(15))
                    .offset(x: 65, y: -85)
            }
            
            // Left arm (wrapped around body)
            VStack(spacing: -5) {
                // Upper arm
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -10, y: -65)
                
                // Forearm
                RoundedRectangle(cornerRadius: 10)
                    .fill(golferGradient)
                    .frame(width: 15, height: 40)
                    .rotationEffect(.degrees(-45))
                    .offset(x: -25, y: -80)
            }
            
            // Lower torso/hips
            RoundedRectangle(cornerRadius: 20)
                .fill(golferGradient)
                .frame(width: 45, height: 35)
                .rotationEffect(.degrees(10))
                .offset(x: 12, y: -10)
            
            // Right leg (supporting weight)
            VStack(spacing: -8) {
                // Thigh
                RoundedRectangle(cornerRadius: 15)
                    .fill(golferGradient)
                    .frame(width: 22, height: 50)
                    .rotationEffect(.degrees(5))
                    .offset(x: 5, y: 25)
                
                // Shin
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(3))
                    .offset(x: 6, y: 55)
                
                // Foot
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 30, height: 12)
                    .offset(x: 7, y: 78)
            }
            
            // Left leg (back foot up on toe)
            VStack(spacing: -8) {
                // Thigh
                RoundedRectangle(cornerRadius: 15)
                    .fill(golferGradient)
                    .frame(width: 22, height: 50)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -15, y: 20)
                
                // Shin
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(-15))
                    .offset(x: -25, y: 45)
                
                // Foot (on toe)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 25, height: 10)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -30, y: 68)
            }
        }
    }
    
    private var golferGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.92, blue: 0.92),
                Color(red: 0.70, green: 0.70, blue: 0.70)
            ],
            startPoint: UnitPoint(x: 0.2, y: 0.1),
            endPoint: UnitPoint(x: 0.8, y: 0.9)
        )
    }
    
    // MARK: - Golf Club
    
    private var golfClub: some View {
        VStack(spacing: 0) {
            // Grip - sculptural
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.82, blue: 0.82),
                            Color(red: 0.65, green: 0.65, blue: 0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 35)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
            
            // Shaft - sleek
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.70, green: 0.70, blue: 0.70),
                            Color(red: 0.55, green: 0.55, blue: 0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 130)
            
            // Club head - modern
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.75, green: 0.75, blue: 0.75),
                            Color(red: 0.60, green: 0.60, blue: 0.60)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 15, height: 22)
                .shadow(color: .black.opacity(0.12), radius: 2, x: 1, y: 1)
        }
    }
}

#Preview {
    ZStack {
        Color.white
        PathBasedGolferFigurine()
    }
    .frame(width: 400, height: 500)
}
