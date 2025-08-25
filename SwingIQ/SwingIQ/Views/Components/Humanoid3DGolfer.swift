//
//  Humanoid3DGolfer.swift
//  SwingIQ
//
//  Created by Amp on 8/7/25.
//  Elegant 3D humanoid golfer with clean, streamlined design
//

import SwiftUI

struct Humanoid3DGolfer: View {
    @State private var swingAnimation = false
    
    let isAnimated: Bool
    
    init(isAnimated: Bool = true) {
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        ZStack {
            // Golf Club positioned in follow-through - extended across body
            modernGolfClub
                .offset(
                    x: swingAnimation ? 45 : 35, 
                    y: swingAnimation ? -45 : -55
                )
                .rotationEffect(.degrees(swingAnimation ? 25 : 15)) // Club in follow-through position
            
            // Main humanoid body - smooth sculptural follow-through pose
            VStack(spacing: -2) { // Negative spacing for seamless flow
                // Head - sculptural, light grey
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                            center: .topLeading,
                            startRadius: 12,
                            endRadius: 25
                        )
                    )
                    .frame(width: 45, height: 45)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 3, y: 3)
                    .offset(x: 18, y: 0) // Head rotated toward target
                
                // Neck - flows seamlessly into torso
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 20)
                    .rotationEffect(.degrees(8))
                
                // Upper body with arms - unified sculptural torso
                ZStack {
                    // Main torso - sculptural grey form
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 90)
                        .rotationEffect(.degrees(35))
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 4, y: 4)
                    
                    // Arms - smooth sculptural extensions
                    ZStack {
                        // Left arm (lead arm) - flowing sculptural form
                        ZStack {
                            // Upper arm segment
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.45)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 58)
                                .rotationEffect(.degrees(25))
                                .offset(x: 30, y: -40)
                            
                            // Forearm segment - seamless continuation
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 48)
                                .rotationEffect(.degrees(15))
                                .offset(x: 60, y: -75)
                        }
                        
                        // Right arm (trail arm) - wrapped sculptural form
                        ZStack {
                            // Upper arm segment
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.45)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 58)
                                .rotationEffect(.degrees(-20))
                                .offset(x: -15, y: -35)
                            
                            // Forearm segment - wrapped around
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 48)
                                .rotationEffect(.degrees(-45))
                                .offset(x: -45, y: -70)
                        }
                    }
                }
                
                // Waist/abdomen - sculptural middle section
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 55, height: 38)
                    .rotationEffect(.degrees(25))
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 3, y: 3)
                
                // Pelvis area - unified with torso
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 35)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 3, y: 3)
                
                // Legs - sculptural flowing stance
                HStack(spacing: 22) {
                    // Left leg (front leg) - solid foundation
                    VStack(spacing: -3) { // Seamless flow
                        // Thigh - sculptural form
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 65)
                            .rotationEffect(.degrees(8))
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 2, y: 2)
                        
                        // Shin - continues seamlessly
                        RoundedRectangle(cornerRadius: 17)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 22, height: 50)
                            .rotationEffect(.degrees(5))
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 2, y: 2)
                        
                        // Foot - sculptural base
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 35, height: 15)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                    }
                    
                    // Right leg (back leg) - elegant dynamic finish
                    VStack(spacing: -3) { // Seamless flow
                        // Thigh - flowing sculptural form
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 65)
                            .rotationEffect(.degrees(-25))
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 2, y: 2)
                        
                        // Shin - elegant extension
                        RoundedRectangle(cornerRadius: 17)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 22, height: 50)
                            .rotationEffect(.degrees(-15))
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 2, y: 2)
                        
                        // Foot - on toe, elegant
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 30, height: 12)
                            .rotationEffect(.degrees(-30))
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
                    }
                }
            }
            .rotationEffect(.degrees(swingAnimation ? 8 : -3)) // Enhanced swing motion from backswing to downswing
        }
        .scaleEffect(swingAnimation ? 1.02 : 1.0)
        .frame(width: 200, height: 280)
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    swingAnimation = true
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func subtleJoint(size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white, Color.gray.opacity(0.15)],
                    center: .topLeading,
                    startRadius: size/4,
                    endRadius: size/2
                )
            )
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 1, y: 1)
    }
    
    private var modernGolfClub: some View {
        VStack(spacing: 0) {
            // Club grip - sculptural handle
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 35)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 1, y: 1)
            
            // Club shaft - elegant, sculptural
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 110)
            
            // Club head - sculptural form
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 16, height: 22)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 1, y: 1)
        }
    }
}

#Preview {
    ZStack {
        Color.white
        Humanoid3DGolfer(isAnimated: true)
    }
    .frame(width: 300, height: 400)
}
