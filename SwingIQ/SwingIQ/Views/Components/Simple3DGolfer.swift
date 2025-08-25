//
//  Simple3DGolfer.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//  Simplified 3D humanoid golfer figurine
//

import SwiftUI

struct Simple3DGolfer: View {
    @State private var animationOffset: CGFloat = 0
    
    let isAnimated: Bool
    
    init(isAnimated: Bool = true) {
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        ZStack {
            // Golf Club (behind figure)
            golfClub
                .offset(x: 40, y: -30)
                .rotationEffect(.degrees(-50))
            
            // Main body figure
            VStack(spacing: 5) {
                // Head
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, Color.gray.opacity(0.3)],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: 12
                        )
                    )
                    .frame(width: 25, height: 25)
                    .shadow(color: .black.opacity(0.1), radius: 1)
                
                // Neck
                Capsule()
                    .fill(Color.white)
                    .frame(width: 6, height: 8)
                
                // Shoulders with joints
                ZStack {
                    // Shoulder bar
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 50, height: 12)
                    
                    // Shoulder joints
                    HStack(spacing: 38) {
                        purpleJoint(size: 10)
                        purpleJoint(size: 10)
                    }
                }
                
                // Arms extending from shoulders
                ZStack {
                    // Left arm (extended back)
                    HStack(spacing: 0) {
                        // Upper arm
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 10, height: 30)
                            .rotationEffect(.degrees(110))
                            .offset(x: -35, y: 10)
                        
                        // Elbow
                        purpleJoint(size: 7)
                            .offset(x: -50, y: 5)
                        
                        // Forearm
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 8, height: 25)
                            .rotationEffect(.degrees(80))
                            .offset(x: -65, y: 15)
                    }
                    
                    // Right arm (bent back)
                    HStack(spacing: 0) {
                        // Upper arm
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 10, height: 30)
                            .rotationEffect(.degrees(70))
                            .offset(x: 25, y: 5)
                        
                        // Elbow
                        purpleJoint(size: 7)
                            .offset(x: 40, y: -5)
                        
                        // Forearm
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 8, height: 25)
                            .rotationEffect(.degrees(40))
                            .offset(x: 55, y: 0)
                    }
                }
                
                // Torso
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 25, height: 45)
                    .shadow(color: .black.opacity(0.05), radius: 1)
                
                // Hip area with joints
                ZStack {
                    // Pelvis
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 28, height: 16)
                    
                    // Hip joints
                    HStack(spacing: 18) {
                        purpleJoint(size: 9)
                        purpleJoint(size: 9)
                    }
                }
                
                // Legs
                HStack(spacing: 12) {
                    // Left leg
                    VStack(spacing: 3) {
                        // Thigh
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 12, height: 35)
                            .rotationEffect(.degrees(5))
                        
                        // Knee
                        purpleJoint(size: 8)
                        
                        // Shin
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 10, height: 30)
                        
                        // Ankle
                        purpleJoint(size: 6)
                        
                        // Foot
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 16, height: 6)
                    }
                    
                    // Right leg
                    VStack(spacing: 3) {
                        // Thigh
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 12, height: 35)
                            .rotationEffect(.degrees(-5))
                        
                        // Knee
                        purpleJoint(size: 8)
                        
                        // Shin
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 10, height: 30)
                        
                        // Ankle
                        purpleJoint(size: 6)
                        
                        // Foot
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 16, height: 6)
                    }
                }
            }
        }
        .scaleEffect(1.0 + animationOffset)
        .frame(width: 140, height: 180)
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animationOffset = 0.03
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func purpleJoint(size: CGFloat) -> some View {
        Circle()
            .fill(Color(red: 0.55, green: 0.36, blue: 0.96))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: size/2
                        )
                    )
            )
            .shadow(color: Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.2), radius: 1)
    }
    
    private var golfClub: some View {
        VStack(spacing: 0) {
            // Club grip
            Capsule()
                .fill(Color.black.opacity(0.8))
                .frame(width: 3, height: 15)
            
            // Club shaft
            Capsule()
                .fill(Color.gray.opacity(0.7))
                .frame(width: 2, height: 70)
            
            // Club head
            Capsule()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 8, height: 12)
        }
    }
}

#Preview {
    ZStack {
        Color.white
        Simple3DGolfer(isAnimated: true)
    }
    .frame(width: 200, height: 250)
}
