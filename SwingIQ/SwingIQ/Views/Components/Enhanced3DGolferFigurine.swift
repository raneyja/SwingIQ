//
//  Enhanced3DGolferFigurine.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//  3D humanoid golfer figurine matching reference image style
//

import SwiftUI

struct Enhanced3DGolferFigurine: View {
    @State private var swingAnimation = false
    
    let isAnimated: Bool
    
    init(isAnimated: Bool = true) {
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        ZStack {
            // Main 3D humanoid golfer
            golferFigurine
                .scaleEffect(swingAnimation ? 1.02 : 1.0)
                .animation(
                    isAnimated ? 
                    Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true) : 
                    .none,
                    value: swingAnimation
                )
        }
        .frame(width: 160, height: 200)
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    swingAnimation = true
                }
            }
        }
    }
    
    // MARK: - Main 3D Humanoid Golfer
    private var golferFigurine: some View {
        ZStack {
            // Golf Club (positioned correctly in backswing)
            golfClub
                .offset(x: 45, y: -25)
                .rotationEffect(.degrees(-45))
            
            // Main body structure
            VStack(spacing: 0) {
                // Head
                head
                    .offset(y: 5)
                
                // Neck connection
                neckConnection
                
                // Upper body with arms
                upperBodyWithArms
                
                // Torso
                torso
                
                // Pelvis with legs
                pelvisWithLegs
            }
        }
    }
    
    // MARK: - Body Components
    
    private var head: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white, Color.gray.opacity(0.3)],
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 15
                )
            )
            .frame(width: 30, height: 30)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
    }
    
    private var neckConnection: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white, Color.gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 8, height: 12)
    }
    
    private var upperBodyWithArms: some View {
        ZStack {
            // Shoulder joints
            HStack(spacing: 50) {
                purpleJoint(size: 12) // Left shoulder
                purpleJoint(size: 12) // Right shoulder
            }
            .offset(y: 15)
            
            // Arms extending from shoulders
            HStack(spacing: 85) {
                // Left arm (extended in backswing)
                leftArmBackswing
                    .offset(x: 15, y: 10)
                
                // Right arm (bent in backswing)
                rightArmBackswing
                    .offset(x: -15, y: 10)
            }
        }
    }
    
    private var torso: some View {
        VStack(spacing: 8) {
            // Upper torso (chest)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 35, height: 50)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
            
            // Waist
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 25)
        }
    }
    
    private var pelvisWithLegs: some View {
        VStack(spacing: 0) {
            // Pelvis
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 20)
                .shadow(color: .black.opacity(0.08), radius: 1, x: 0.5, y: 0.5)
            
            // Hip joints
            HStack(spacing: 20) {
                purpleJoint(size: 10) // Left hip
                purpleJoint(size: 10) // Right hip
            }
            .offset(y: 8)
            
            // Legs
            HStack(spacing: 15) {
                // Left leg
                legComponent(isLeft: true)
                    .offset(y: 15)
                
                // Right leg  
                legComponent(isLeft: false)
                    .offset(y: 15)
            }
        }
    }
    
    // MARK: - Arm Components
    
    private var leftArmBackswing: some View {
        VStack(spacing: 0) {
            // Upper arm
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 35)
                .rotationEffect(.degrees(120)) // Extended back in swing
            
            // Elbow joint
            purpleJoint(size: 8)
                .offset(x: -25, y: -5)
            
            // Forearm
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 30)
                .rotationEffect(.degrees(90))
                .offset(x: -40, y: 5)
        }
    }
    
    private var rightArmBackswing: some View {
        VStack(spacing: 0) {
            // Upper arm
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 35)
                .rotationEffect(.degrees(60)) // Bent back in swing
            
            // Elbow joint
            purpleJoint(size: 8)
                .offset(x: 20, y: -10)
            
            // Forearm
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 30)
                .rotationEffect(.degrees(45))
                .offset(x: 35, y: -5)
        }
    }
    
    // MARK: - Leg Component
    
    private func legComponent(isLeft: Bool) -> some View {
        VStack(spacing: 0) {
            // Thigh
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14, height: 40)
                .rotationEffect(.degrees(isLeft ? 5 : -5)) // Slight stance spread
            
            // Knee joint
            purpleJoint(size: 9)
                .offset(y: 5)
            
            // Shin
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 35)
                .offset(y: 10)
            
            // Ankle joint
            purpleJoint(size: 7)
                .offset(y: 20)
            
            // Foot
            Capsule()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 20, height: 8)
                .offset(y: 25)
        }
    }
    
    // MARK: - Purple Joint Component
    
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
            .shadow(color: Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.3), radius: 2, x: 0.5, y: 0.5)
    }
    
    // MARK: - Golf Club
    
    private var golfClub: some View {
        VStack(spacing: 0) {
            // Club grip
            Capsule()
                .fill(Color.black.opacity(0.8))
                .frame(width: 4, height: 20)
            
            // Club shaft
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 85)
            
            // Club head
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 15)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0.5, y: 0.5)
        }
    }
}

#Preview {
    ZStack {
        Color.white
        Enhanced3DGolferFigurine(isAnimated: true)
    }
    .frame(width: 300, height: 400)
}
