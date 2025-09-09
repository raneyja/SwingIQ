//
//  SpinningGolfBall.swift
//  SwingIQ
//
//  Created by Amp on 8/27/25.
//

import SwiftUI

struct SpinningGolfBall: View {
    let isAnimated: Bool
    @State private var rotationAngle: Double = 0
    @State private var dimplePhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Main golf ball body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.gray.opacity(0.05),
                                Color.gray.opacity(0.12)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.25),
                            startRadius: size * 0.1,
                            endRadius: size * 0.5
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: size * 0.08, x: size * 0.04, y: size * 0.05)
                
                // Realistic golf ball dimple pattern - fewer, larger dimples
                ForEach(0..<8, id: \.self) { ring in
                    let ringRadius = size * 0.05 + Double(ring) * size * 0.055
                    let dimpleCount = ring == 0 ? 1 : ring * 5
                    
                    ForEach(0..<dimpleCount, id: \.self) { dimple in
                        let angle = ring == 0 ? 0 : (Double(dimple) / Double(dimpleCount)) * 360.0 + dimplePhase + Double(ring) * 36.0
                        let x = ring == 0 ? 0 : cos(angle * .pi / 180) * ringRadius
                        let y = ring == 0 ? 0 : sin(angle * .pi / 180) * ringRadius
                        
                        // Calculate distance from center for spherical scaling
                        let distance = sqrt(x * x + y * y)
                        let maxRadius = size * 0.42
                        
                        if distance <= maxRadius {
                            // Apply spherical projection
                            let sphericalScale = 1.0 - pow(distance / maxRadius, 1.6)
                            let dimpleSize = size * 0.12 * (0.8 + sphericalScale * 0.4)
                            
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.gray.opacity(0.6 * sphericalScale),
                                            Color.gray.opacity(0.35 * sphericalScale),
                                            Color.gray.opacity(0.1 * sphericalScale),
                                            Color.clear
                                        ],
                                        center: UnitPoint(x: 0.3, y: 0.2),
                                        startRadius: dimpleSize * 0.1,
                                        endRadius: dimpleSize * 0.9
                                    )
                                )
                                .frame(width: dimpleSize, height: dimpleSize)
                                .offset(x: x, y: y)
                                .opacity(sphericalScale > 0.15 ? 1.0 : 0.4)
                        }
                    }
                }
                
                // Highlight shine
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: size * 0.15
                        )
                    )
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(x: -size * 0.12, y: -size * 0.15)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            if isAnimated {
                startSpinning()
            }
        }
        .onChange(of: isAnimated) { animated in
            if animated {
                startSpinning()
            } else {
                withAnimation(.easeOut(duration: 1.0)) {
                    rotationAngle = 0
                    dimplePhase = 0
                }
            }
        }
    }
    
    private func startSpinning() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            dimplePhase = 360
        }
    }
}

// MARK: - Preview

struct SpinningGolfBall_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            SpinningGolfBall(isAnimated: true)
                .frame(width: 80, height: 80)
            
            SpinningGolfBall(isAnimated: false)
                .frame(width: 80, height: 80)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
