//
//  SculpturalGolferFigurine.swift
//  SwingIQ
//
//  Created by Amp on 8/8/25.
//  Exact replica of the 3D sculptural golfer figurine
//

import SwiftUI

struct SculpturalGolferFigurine: View {
    var body: some View {
        ZStack {
            // Golf club extending from hands
            golfClub
                .offset(x: -15, y: -50)
                .rotationEffect(.degrees(-35))
            
            // Unified sculptural figure - single carved form
            ZStack {
                // Main body mass - one unified sculptural form
                sculpturedBody
                
                // Head integrated into body
                sculpturedHead
                
                // Arms as part of the unified body
                sculpturedArms
                
                // Legs flowing from the torso
                sculpturedLegs
            }
        }
        .frame(width: 200, height: 280)
    }
    
    // MARK: - Unified Body Components
    
    private var sculpturedHead: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.95),
                        Color(red: 0.75, green: 0.75, blue: 0.75)
                    ],
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 8,
                    endRadius: 30
                )
            )
            .frame(width: 40, height: 40)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 3, y: 3)
            .offset(x: 20, y: -110)
                
    }
    
    private var sculpturedBody: some View {
        // Single unified torso that flows naturally
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.92, blue: 0.92),
                        Color(red: 0.68, green: 0.68, blue: 0.68)
                    ],
                    startPoint: UnitPoint(x: 0.2, y: 0.1),
                    endPoint: UnitPoint(x: 0.8, y: 0.9)
                )
            )
            .frame(width: 80, height: 140)
            .rotationEffect(.degrees(25)) // Turned toward target
            .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 5)
            .offset(x: 15, y: -35)
                
    }
    
    private var sculpturedArms: some View {
        ZStack {
            // Left arm - extended across body in follow-through
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.90, blue: 0.90),
                            Color(red: 0.65, green: 0.65, blue: 0.65)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.2),
                        endPoint: UnitPoint(x: 0.8, y: 0.8)
                    )
                )
                .frame(width: 25, height: 100)
                .rotationEffect(.degrees(30))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                .offset(x: 50, y: -70)
                    
            // Right arm - wrapped around body in follow-through
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.88, blue: 0.88),
                            Color(red: 0.63, green: 0.63, blue: 0.63)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.2),
                        endPoint: UnitPoint(x: 0.8, y: 0.8)
                    )
                )
                .frame(width: 22, height: 95)
                .rotationEffect(.degrees(-25))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                .offset(x: -25, y: -60)
        }
    }
    
    private var sculpturedLegs: some View {
        ZStack {
            // Left leg (front) - supporting weight
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.90, blue: 0.90),
                            Color(red: 0.65, green: 0.65, blue: 0.65)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.8, y: 0.9)
                    )
                )
                .frame(width: 30, height: 110)
                .rotationEffect(.degrees(8))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 3, y: 3)
                .offset(x: -15, y: 60)
            
            // Right leg (back) - up on toe, dynamic finish
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.88, blue: 0.88),
                            Color(red: 0.63, green: 0.63, blue: 0.63)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.8, y: 0.9)
                    )
                )
                .frame(width: 28, height: 105)
                .rotationEffect(.degrees(-30))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 3, y: 3)
                .offset(x: 25, y: 55)
            
            // Feet - sculptural base
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.85, blue: 0.85),
                            Color(red: 0.60, green: 0.60, blue: 0.60)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.2),
                        endPoint: UnitPoint(x: 0.8, y: 0.8)
                    )
                )
                .frame(width: 35, height: 15)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
                .offset(x: -15, y: 115)
            
            // Right foot - on toe
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.83, green: 0.83, blue: 0.83),
                            Color(red: 0.58, green: 0.58, blue: 0.58)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.2),
                        endPoint: UnitPoint(x: 0.8, y: 0.8)
                    )
                )
                .frame(width: 30, height: 12)
                .rotationEffect(.degrees(-35))
                .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
                .offset(x: 30, y: 105)
        }
                
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
        SculpturalGolferFigurine()
    }
    .frame(width: 400, height: 500)
}
