//
//  TestCoordinateOverlay.swift
//  SwingIQ
//
//  Simple test overlay to verify coordinate system alignment
//

import SwiftUI

struct TestCoordinateOverlay: View {
    let geometry: GeometryProxy
    let videoSize: CGSize?
    
    var body: some View {
        Canvas { context, size in
            // Draw reference grid and test shapes to verify coordinate alignment
            drawTestShapes(context: context, size: size)
        }
    }
    
    private func drawTestShapes(context: GraphicsContext, size: CGSize) {
        // Calculate video rect using same logic as MediaPipe overlay
        let videoRect = calcVideoRect(in: size, videoSize: videoSize)
        
        // Draw video bounds rectangle in red
        var videoBounds = Path()
        videoBounds.addRect(videoRect)
        context.stroke(videoBounds, with: .color(.red), style: StrokeStyle(lineWidth: 3))
        
        // Draw test points at key locations
        let testPoints = [
            (CGPoint(x: 0.3, y: 0.2), Color.blue),    // Upper body area
            (CGPoint(x: 0.5, y: 0.5), Color.green),   // Center
            (CGPoint(x: 0.4, y: 0.8), Color.purple),  // Lower body area
            (CGPoint(x: 0.6, y: 0.8), Color.orange)   // Lower body area
        ]
        
        for (normalizedPoint, color) in testPoints {
            let screenPoint = CGPoint(
                x: videoRect.minX + normalizedPoint.x * videoRect.width,
                y: videoRect.minY + normalizedPoint.y * videoRect.height
            )
            
            // Draw large visible circle
            let circle = Path(ellipseIn: CGRect(
                origin: CGPoint(x: screenPoint.x - 15, y: screenPoint.y - 15),
                size: CGSize(width: 30, height: 30)
            ))
            context.fill(circle, with: .color(color))
            context.stroke(circle, with: .color(.white), style: StrokeStyle(lineWidth: 2))
        }
        
        // Draw comprehensive debug info
        let debugInfo = [
            "Canvas: \(Int(size.width))x\(Int(size.height))",
            "VideoSize: \(videoSize?.width ?? 0)x\(videoSize?.height ?? 0)",
            "VideoRect: \(Int(videoRect.width))x\(Int(videoRect.height))",
            "VideoRect Origin: \(Int(videoRect.minX)),\(Int(videoRect.minY))",
            "Aspect: video=\(String(format: "%.2f", (videoSize?.width ?? 1) / (videoSize?.height ?? 1))), view=\(String(format: "%.2f", size.width / size.height))"
        ]
        
        for (index, info) in debugInfo.enumerated() {
            context.draw(
                Text(info)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow),
                at: CGPoint(x: 20, y: 30 + CGFloat(index * 20))
            )
        }
        
        // Print to console as well
        print("🔍 COORDINATE DEBUG:")
        debugInfo.forEach { print("   \($0)") }
    }
    
    private func calcVideoRect(in viewSize: CGSize, videoSize: CGSize?) -> CGRect {
        guard let videoSize = videoSize, videoSize.width > 0, videoSize.height > 0 else {
            return CGRect(origin: .zero, size: viewSize)
        }
        
        let videoAspect = videoSize.width / videoSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        if viewAspect > videoAspect {
            // View is wider → black bars on left & right
            let height = viewSize.height
            let width = height * videoAspect
            let x = (viewSize.width - width) / 2.0
            return CGRect(x: x, y: 0, width: width, height: height)
        } else {
            // View is taller → black bars on top & bottom
            let width = viewSize.width
            let height = width / videoAspect
            let y = (viewSize.height - height) / 2.0
            return CGRect(x: 0, y: y, width: width, height: height)
        }
    }
}
