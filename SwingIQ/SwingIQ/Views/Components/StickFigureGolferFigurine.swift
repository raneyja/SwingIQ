//
//  StickFigureGolferFigurine.swift
//  SwingIQ
//
//  Clean stick figure golfer using Path
//

import SwiftUI

struct StickFigureGolferFigurine: View {
    var body: some View {
        ZStack {
            // Golfer stick figure in follow-through pose
            golferStickFigure
            
            // Golf club
            golfClubStick
            
            // Head (circle)
            Circle()
                .stroke(Color.primary, lineWidth: 3)
                .frame(width: 20, height: 20)
                .offset(x: 15, y: -120)
        }
        .frame(width: 200, height: 280)
    }
    
    private var golferStickFigure: some View {
        Path { path in
            // Body center point
            let centerX: CGFloat = 100
            let centerY: CGFloat = 140
            
            // Torso (vertical line, slightly tilted for follow-through)
            path.move(to: CGPoint(x: centerX + 10, y: centerY - 60))  // neck
            path.addLine(to: CGPoint(x: centerX + 5, y: centerY + 20)) // hip
            
            // Left arm (across body in follow-through)
            path.move(to: CGPoint(x: centerX + 8, y: centerY - 40))   // shoulder
            path.addLine(to: CGPoint(x: centerX - 20, y: centerY - 30)) // elbow
            path.addLine(to: CGPoint(x: centerX - 10, y: centerY - 10)) // hand
            
            // Right arm (extended up in follow-through)
            path.move(to: CGPoint(x: centerX + 12, y: centerY - 40))  // shoulder
            path.addLine(to: CGPoint(x: centerX + 40, y: centerY - 60)) // elbow
            path.addLine(to: CGPoint(x: centerX + 60, y: centerY - 80)) // hand
            
            // Left leg (back leg, on toe)
            path.move(to: CGPoint(x: centerX + 3, y: centerY + 20))   // hip
            path.addLine(to: CGPoint(x: centerX - 15, y: centerY + 60)) // knee
            path.addLine(to: CGPoint(x: centerX - 20, y: centerY + 100)) // ankle
            
            // Right leg (front leg, planted)
            path.move(to: CGPoint(x: centerX + 7, y: centerY + 20))   // hip
            path.addLine(to: CGPoint(x: centerX + 10, y: centerY + 60)) // knee
            path.addLine(to: CGPoint(x: centerX + 8, y: centerY + 100)) // ankle
        }
        .stroke(Color.primary, lineWidth: 3)
    }
    
    private var golfClubStick: some View {
        Path { path in
            // Golf club shaft (from right hand up and around)
            path.move(to: CGPoint(x: 160, y: 60))  // hand position
            path.addLine(to: CGPoint(x: 180, y: 40)) // club head
        }
        .stroke(Color.secondary, lineWidth: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Stick Figure Golfer")
        StickFigureGolferFigurine()
            .background(Color.white)
    }
    .frame(width: 400, height: 500)
}
