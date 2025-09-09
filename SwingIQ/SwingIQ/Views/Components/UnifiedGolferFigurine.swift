//
//  UnifiedGolferFigurine.swift
//  SwingIQ
//
//  Created by Amp on 8/26/25.
//  Unified golfer figurine component with multiple style options
//

import SwiftUI
import SceneKit

// MARK: - Figurine Style Enum

enum GolferFigurineStyle: String, CaseIterable {
    case enhanced3D = "Enhanced 3D"
    case stickFigure = "Stick Figure"
    case sceneKit = "SceneKit 3D"
    case sculptural = "Sculptural"
    case pathBased = "Path Based"
    case staticPose = "Static Pose"
    case sfSymbol = "SF Symbol"
    case image = "Image"
}

// MARK: - Unified Golfer Figurine

struct UnifiedGolferFigurine: View {
    let style: GolferFigurineStyle
    let isAnimated: Bool
    let size: CGSize
    
    init(
        style: GolferFigurineStyle = .enhanced3D,
        isAnimated: Bool = true,
        size: CGSize = CGSize(width: 200, height: 280)
    ) {
        self.style = style
        self.isAnimated = isAnimated
        self.size = size
    }
    
    var body: some View {
        Group {
            switch style {
            case .enhanced3D:
                Enhanced3DFigurineContent(isAnimated: isAnimated)
            case .stickFigure:
                StickFigurineContent()
            case .sceneKit:
                SceneKitFigurineContent()
            case .sculptural:
                SculpturalFigurineContent()
            case .pathBased:
                PathBasedFigurineContent()
            case .staticPose:
                StaticPoseFigurineContent()
            case .sfSymbol:
                SFSymbolFigurineContent()
            case .image:
                ImageFigurineContent()
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Enhanced 3D Figurine Content

private struct Enhanced3DFigurineContent: View {
    @State private var swingAnimation = false
    let isAnimated: Bool
    
    var body: some View {
        ZStack {
            golferFigurine
                .scaleEffect(swingAnimation ? 1.02 : 1.0)
                .animation(
                    isAnimated ? 
                    Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true) : 
                    .none,
                    value: swingAnimation
                )
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    swingAnimation = true
                }
            }
        }
    }
    
    private var golferFigurine: some View {
        ZStack {
            golfClub
                .offset(x: 45, y: -25)
                .rotationEffect(.degrees(-45))
            
            VStack(spacing: 0) {
                head.offset(y: 5)
                neckConnection
                upperBodyWithArms
                torso
                pelvisWithLegs
            }
        }
    }
    
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
            HStack(spacing: 50) {
                purpleJoint(size: 12)
                purpleJoint(size: 12)
            }
            .offset(y: 15)
            
            HStack(spacing: 85) {
                leftArmBackswing.offset(x: 15, y: 10)
                rightArmBackswing.offset(x: -15, y: 10)
            }
        }
    }
    
    private var torso: some View {
        VStack(spacing: 8) {
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
            
            HStack(spacing: 20) {
                purpleJoint(size: 10)
                purpleJoint(size: 10)
            }
            .offset(y: 8)
            
            HStack(spacing: 15) {
                legComponent(isLeft: true).offset(y: 15)
                legComponent(isLeft: false).offset(y: 15)
            }
        }
    }
    
    private var leftArmBackswing: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 35)
                .rotationEffect(.degrees(120))
            
            purpleJoint(size: 8)
                .offset(x: -25, y: -5)
            
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
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 35)
                .rotationEffect(.degrees(60))
            
            purpleJoint(size: 8)
                .offset(x: 20, y: -10)
            
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
    
    private func legComponent(isLeft: Bool) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14, height: 40)
                .rotationEffect(.degrees(isLeft ? 5 : -5))
            
            purpleJoint(size: 9)
                .offset(y: 5)
            
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
            
            purpleJoint(size: 7)
                .offset(y: 20)
            
            Capsule()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 20, height: 8)
                .offset(y: 25)
        }
    }
    
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
    
    private var golfClub: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.black.opacity(0.8))
                .frame(width: 4, height: 20)
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 85)
            
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

// MARK: - Stick Figure Content

private struct StickFigurineContent: View {
    var body: some View {
        ZStack {
            golferStickFigure
            golfClubStick
            
            Circle()
                .stroke(Color.primary, lineWidth: 3)
                .frame(width: 20, height: 20)
                .offset(x: 15, y: -120)
        }
    }
    
    private var golferStickFigure: some View {
        Path { path in
            let centerX: CGFloat = 100
            let centerY: CGFloat = 140
            
            path.move(to: CGPoint(x: centerX + 10, y: centerY - 60))
            path.addLine(to: CGPoint(x: centerX + 5, y: centerY + 20))
            
            path.move(to: CGPoint(x: centerX + 8, y: centerY - 40))
            path.addLine(to: CGPoint(x: centerX - 20, y: centerY - 30))
            path.addLine(to: CGPoint(x: centerX - 10, y: centerY - 10))
            
            path.move(to: CGPoint(x: centerX + 12, y: centerY - 40))
            path.addLine(to: CGPoint(x: centerX + 40, y: centerY - 60))
            path.addLine(to: CGPoint(x: centerX + 60, y: centerY - 80))
            
            path.move(to: CGPoint(x: centerX + 3, y: centerY + 20))
            path.addLine(to: CGPoint(x: centerX - 15, y: centerY + 60))
            path.addLine(to: CGPoint(x: centerX - 20, y: centerY + 100))
            
            path.move(to: CGPoint(x: centerX + 7, y: centerY + 20))
            path.addLine(to: CGPoint(x: centerX + 10, y: centerY + 60))
            path.addLine(to: CGPoint(x: centerX + 8, y: centerY + 100))
        }
        .stroke(Color.primary, lineWidth: 3)
    }
    
    private var golfClubStick: some View {
        Path { path in
            path.move(to: CGPoint(x: 160, y: 60))
            path.addLine(to: CGPoint(x: 180, y: 40))
        }
        .stroke(Color.secondary, lineWidth: 2)
    }
}

// MARK: - SceneKit Content

private struct SceneKitFigurineContent: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createGolferScene()
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = UIColor.clear
        sceneView.autoenablesDefaultLighting = true
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    private func createGolferScene() -> SCNScene {
        let scene = SCNScene()
        
        let golferNode = createGolferFigure()
        scene.rootNode.addChildNode(golferNode)
        
        let clubNode = createGolfClub()
        golferNode.addChildNode(clubNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 8)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private func createGolferFigure() -> SCNNode {
        let golferNode = SCNNode()
        
        let head = SCNSphere(radius: 0.3)
        head.firstMaterial?.diffuse.contents = UIColor.systemGray4
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 2.5, 0)
        golferNode.addChildNode(headNode)
        
        let torso = SCNCylinder(radius: 0.4, height: 1.2)
        torso.firstMaterial?.diffuse.contents = UIColor.systemGray3
        let torsoNode = SCNNode(geometry: torso)
        torsoNode.position = SCNVector3(0, 1.5, 0)
        torsoNode.rotation = SCNVector4(0, 0, 1, Float.pi * 0.1)
        golferNode.addChildNode(torsoNode)
        
        createArm(parent: golferNode, side: "left", x: -0.5, rotation: -0.3)
        createArm(parent: golferNode, side: "right", x: 0.5, rotation: 0.5)
        
        createLeg(parent: golferNode, side: "left", x: -0.2)
        createLeg(parent: golferNode, side: "right", x: 0.2)
        
        return golferNode
    }
    
    private func createArm(parent: SCNNode, side: String, x: Float, rotation: Float) {
        let upperArm = SCNCylinder(radius: 0.1, height: 0.8)
        upperArm.firstMaterial?.diffuse.contents = UIColor.systemGray4
        let upperArmNode = SCNNode(geometry: upperArm)
        upperArmNode.position = SCNVector3(x, 1.8, 0)
        upperArmNode.rotation = SCNVector4(0, 0, 1, rotation)
        parent.addChildNode(upperArmNode)
        
        let forearm = SCNCylinder(radius: 0.08, height: 0.7)
        forearm.firstMaterial?.diffuse.contents = UIColor.systemGray4
        let forearmNode = SCNNode(geometry: forearm)
        forearmNode.position = SCNVector3(x * 1.5, 1.2, 0)
        forearmNode.rotation = SCNVector4(0, 0, 1, rotation * 0.7)
        parent.addChildNode(forearmNode)
    }
    
    private func createLeg(parent: SCNNode, side: String, x: Float) {
        let thigh = SCNCylinder(radius: 0.12, height: 0.9)
        thigh.firstMaterial?.diffuse.contents = UIColor.systemGray3
        let thighNode = SCNNode(geometry: thigh)
        thighNode.position = SCNVector3(x, 0.5, 0)
        parent.addChildNode(thighNode)
        
        let shin = SCNCylinder(radius: 0.1, height: 0.8)
        shin.firstMaterial?.diffuse.contents = UIColor.systemGray3
        let shinNode = SCNNode(geometry: shin)
        shinNode.position = SCNVector3(x, -0.3, 0)
        parent.addChildNode(shinNode)
    }
    
    private func createGolfClub() -> SCNNode {
        let clubNode = SCNNode()
        
        let shaft = SCNCylinder(radius: 0.02, height: 3.0)
        shaft.firstMaterial?.diffuse.contents = UIColor.systemGray
        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.position = SCNVector3(0.8, 1.0, 0)
        shaftNode.rotation = SCNVector4(0, 0, 1, Float.pi * 0.3)
        clubNode.addChildNode(shaftNode)
        
        let head = SCNBox(width: 0.3, height: 0.1, length: 0.15, chamferRadius: 0.02)
        head.firstMaterial?.diffuse.contents = UIColor.darkGray
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(1.8, -0.3, 0)
        clubNode.addChildNode(headNode)
        
        return clubNode
    }
}

// MARK: - Sculptural Content

private struct SculpturalFigurineContent: View {
    var body: some View {
        ZStack {
            golfClub
                .offset(x: -15, y: -50)
                .rotationEffect(.degrees(-35))
            
            ZStack {
                sculpturedBody
                sculpturedHead
                sculpturedArms
                sculpturedLegs
            }
        }
    }
    
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
            .rotationEffect(.degrees(25))
            .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 5)
            .offset(x: 15, y: -35)
    }
    
    private var sculpturedArms: some View {
        ZStack {
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
    
    private var golfClub: some View {
        VStack(spacing: 0) {
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

// MARK: - Path Based Content

private struct PathBasedFigurineContent: View {
    var body: some View {
        ZStack {
            golfClub
                .offset(x: 30, y: -60)
                .rotationEffect(.degrees(25))
            
            humanGolferFigure
        }
    }
    
    private var humanGolferFigure: some View {
        ZStack {
            Circle()
                .fill(golferGradient)
                .frame(width: 35, height: 35)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                .offset(x: 25, y: -110)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(golferGradient)
                .frame(width: 16, height: 20)
                .offset(x: 22, y: -95)
            
            RoundedRectangle(cornerRadius: 25)
                .fill(golferGradient)
                .frame(width: 50, height: 80)
                .rotationEffect(.degrees(15))
                .shadow(color: .black.opacity(0.25), radius: 6, x: 3, y: 3)
                .offset(x: 15, y: -50)
            
            VStack(spacing: -5) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(25))
                    .offset(x: 45, y: -70)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(golferGradient)
                    .frame(width: 15, height: 40)
                    .rotationEffect(.degrees(15))
                    .offset(x: 65, y: -85)
            }
            
            VStack(spacing: -5) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -10, y: -65)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(golferGradient)
                    .frame(width: 15, height: 40)
                    .rotationEffect(.degrees(-45))
                    .offset(x: -25, y: -80)
            }
            
            RoundedRectangle(cornerRadius: 20)
                .fill(golferGradient)
                .frame(width: 45, height: 35)
                .rotationEffect(.degrees(10))
                .offset(x: 12, y: -10)
            
            VStack(spacing: -8) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(golferGradient)
                    .frame(width: 22, height: 50)
                    .rotationEffect(.degrees(5))
                    .offset(x: 5, y: 25)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(3))
                    .offset(x: 6, y: 55)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 30, height: 12)
                    .offset(x: 7, y: 78)
            }
            
            VStack(spacing: -8) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(golferGradient)
                    .frame(width: 22, height: 50)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -15, y: 20)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(golferGradient)
                    .frame(width: 18, height: 45)
                    .rotationEffect(.degrees(-15))
                    .offset(x: -25, y: 45)
                
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
    
    private var golfClub: some View {
        VStack(spacing: 0) {
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

// MARK: - Static Pose Content

private struct StaticPoseFigurineContent: View {
    var body: some View {
        // Fallback to stick figure for static pose since SwingPose3DView requires complex 3D setup
        StickFigurineContent()
    }
}

// MARK: - SF Symbol Content

private struct SFSymbolFigurineContent: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.golf")
                .font(.system(size: 120, weight: .regular))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Image Content

private struct ImageFigurineContent: View {
    var body: some View {
        HStack {
            Spacer()
            
            Group {
                if let _ = UIImage(named: "golfer-figurine") {
                    Image("golfer-figurine")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.clear)
                        .colorMultiply(Color.white.opacity(0.95))
                } else if let _ = UIImage(named: "golfer-figurine 1") {
                    Image("golfer-figurine 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 100))
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 406, height: 569)
            .offset(x: -40)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Unified Golfer Figurine Styles")
            .font(.title2)
            .bold()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
            ForEach(GolferFigurineStyle.allCases, id: \.self) { style in
                VStack {
                    Text(style.rawValue)
                        .font(.caption)
                        .bold()
                    
                    UnifiedGolferFigurine(
                        style: style,
                        isAnimated: false,
                        size: CGSize(width: 120, height: 160)
                    )
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 2)
                }
            }
        }
    }
    .padding()
}
