//
//  ThreeDModelView.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import SwiftUI
import SceneKit
import CoreGraphics

struct ThreeDModelView: UIViewRepresentable {
    let poseKeypoints: [CGPoint]
    let showSkeleton: Bool
    let showTrajectory: Bool
    
    init(poseKeypoints: [CGPoint] = [], showSkeleton: Bool = true, showTrajectory: Bool = false) {
        self.poseKeypoints = poseKeypoints
        self.showSkeleton = showSkeleton
        self.showTrajectory = showTrajectory
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = false
        sceneView.backgroundColor = UIColor.black
        sceneView.autoenablesDefaultLighting = true
        
        // Configure camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        updatePoseVisualization(in: uiView)
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Add ground plane
        let groundGeometry = SCNPlane(width: 20, height: 20)
        groundGeometry.materials.first?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.3)
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.eulerAngles.x = -Float.pi / 2
        groundNode.position.y = -5
        scene.rootNode.addChildNode(groundNode)
        
        // Add lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // Add ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.white.withAlphaComponent(0.3)
        scene.rootNode.addChildNode(ambientLightNode)
        
        return scene
    }
    
    private func updatePoseVisualization(in sceneView: SCNView) {
        guard let scene = sceneView.scene else { return }
        
        // Remove existing pose nodes
        scene.rootNode.childNodes.forEach { node in
            if node.name?.hasPrefix("pose_") == true {
                node.removeFromParentNode()
            }
        }
        
        if showSkeleton {
            addSkeletonVisualization(to: scene)
        }
        
        if showTrajectory {
            addTrajectoryVisualization(to: scene)
        }
    }
    
    private func addSkeletonVisualization(to scene: SCNScene) {
        guard poseKeypoints.count >= 12 else { return } // Need minimum keypoints for skeleton
        
        // Convert 2D keypoints to 3D positions (simplified mapping)
        let joints3D = convert2DTo3D(keypoints: poseKeypoints)
        
        // Add joint spheres
        for (index, position) in joints3D.enumerated() {
            let sphere = SCNSphere(radius: 0.1)
            sphere.materials.first?.diffuse.contents = getJointColor(for: index)
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = position
            sphereNode.name = "pose_joint_\(index)"
            scene.rootNode.addChildNode(sphereNode)
        }
        
        // Add skeleton connections
        let connections = getSkeletonConnections()
        for connection in connections {
            if connection.from < joints3D.count && connection.to < joints3D.count {
                let fromPos = joints3D[connection.from]
                let toPos = joints3D[connection.to]
                
                let boneNode = createBone(from: fromPos, to: toPos)
                boneNode.name = "pose_bone_\(connection.from)_\(connection.to)"
                scene.rootNode.addChildNode(boneNode)
            }
        }
    }
    
    private func addTrajectoryVisualization(to scene: SCNScene) {
        // This would show the trajectory of key points over time
        // For now, we'll add a simple path visualization
        
        if poseKeypoints.count >= 2 {
            let positions = convert2DTo3D(keypoints: Array(poseKeypoints.prefix(2)))
            
            let pathGeometry = SCNGeometry()
            let pathNode = SCNNode(geometry: pathGeometry)
            pathNode.name = "pose_trajectory"
            
            // Add trajectory line (simplified)
            let line = createLine(from: positions[0], to: positions[1])
            line.name = "pose_trajectory_line"
            scene.rootNode.addChildNode(line)
        }
    }
    
    private func convert2DTo3D(keypoints: [CGPoint]) -> [SCNVector3] {
        // Convert 2D pose keypoints to 3D positions
        // This is a simplified conversion - in production you'd use proper depth estimation
        
        return keypoints.enumerated().map { index, point in
            let x = Float((point.x - 0.5) * 10) // Scale and center
            let y = Float((0.5 - point.y) * 10) // Flip Y and scale
            let z = Float(0) // No depth information in 2D pose
            
            return SCNVector3(x, y, z)
        }
    }
    
    private func getJointColor(for index: Int) -> UIColor {
        // Color code joints by body part
        switch index {
        case 0...8: // Head and neck
            return .yellow
        case 9...16: // Arms and hands
            return .blue
        case 17...22: // Torso
            return .green
        case 23...28: // Legs and feet
            return .red
        default:
            return .white
        }
    }
    
    private func getSkeletonConnections() -> [BoneConnection] {
        // Define the connections between joints to form a skeleton
        return [
            // Head connections
            BoneConnection(from: 0, to: 1), // Nose to left eye
            BoneConnection(from: 0, to: 2), // Nose to right eye
            BoneConnection(from: 1, to: 3), // Left eye to left ear
            BoneConnection(from: 2, to: 4), // Right eye to right ear
            
            // Torso connections
            BoneConnection(from: 5, to: 6), // Left shoulder to right shoulder
            BoneConnection(from: 5, to: 11), // Left shoulder to left hip
            BoneConnection(from: 6, to: 12), // Right shoulder to right hip
            BoneConnection(from: 11, to: 12), // Left hip to right hip
            
            // Left arm
            BoneConnection(from: 5, to: 7), // Left shoulder to left elbow
            BoneConnection(from: 7, to: 9), // Left elbow to left wrist
            
            // Right arm
            BoneConnection(from: 6, to: 8), // Right shoulder to right elbow
            BoneConnection(from: 8, to: 10), // Right elbow to right wrist
            
            // Left leg
            BoneConnection(from: 11, to: 13), // Left hip to left knee
            BoneConnection(from: 13, to: 15), // Left knee to left ankle
            
            // Right leg
            BoneConnection(from: 12, to: 14), // Right hip to right knee
            BoneConnection(from: 14, to: 16), // Right knee to right ankle
        ]
    }
    
    private func createBone(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let distance = distanceBetween(from, to)
        let cylinder = SCNCylinder(radius: 0.02, height: CGFloat(distance))
        cylinder.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        
        let boneNode = SCNNode(geometry: cylinder)
        
        // Position the bone between the two joints
        boneNode.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        
        // Orient the bone to point from one joint to the other
        boneNode.look(at: to, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 1, 0))
        
        return boneNode
    }
    
    private func createLine(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let source = SCNGeometrySource(vertices: [from, to])
        let indices: [Int32] = [0, 1]
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        let geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.materials.first?.diffuse.contents = UIColor.cyan
        
        return SCNNode(geometry: geometry)
    }
    
    private func distanceBetween(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        let dx = a.x - b.x
        let dy = a.y - b.y
        let dz = a.z - b.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}

// MARK: - Supporting Types

struct BoneConnection {
    let from: Int
    let to: Int
}

// MARK: - 3D Swing Analysis View

struct SwingAnalysis3DView: View {
    @StateObject private var mediaPipeService = MediaPipeService()
    @State private var showControls = true
    @State private var showSkeleton = true
    @State private var showTrajectory = false
    @State private var playbackSpeed: Double = 1.0
    @State private var currentFrame = 0
    
    let swingFrames: [PoseFrame]
    
    init(swingFrames: [PoseFrame] = []) {
        self.swingFrames = swingFrames
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 3D Visualization
            ThreeDModelView(
                poseKeypoints: currentPoseKeypoints,
                showSkeleton: showSkeleton,
                showTrajectory: showTrajectory
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showControls {
                // Controls
                VStack(spacing: 16) {
                    // Playback controls
                    HStack {
                        Button("⏮") { currentFrame = 0 }
                        Button("⏯") { /* Play/pause logic */ }
                        Button("⏭") { currentFrame = min(swingFrames.count - 1, currentFrame + 1) }
                        
                        Spacer()
                        
                        Text("Frame: \(currentFrame + 1)/\(swingFrames.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Frame scrubber
                    if !swingFrames.isEmpty {
                        Slider(
                            value: Binding(
                                get: { Double(currentFrame) },
                                set: { currentFrame = Int($0) }
                            ),
                            in: 0...Double(max(0, swingFrames.count - 1)),
                            step: 1
                        )
                    }
                    
                    // Visualization options
                    HStack {
                        Toggle("Skeleton", isOn: $showSkeleton)
                        Toggle("Trajectory", isOn: $showTrajectory)
                        
                        Spacer()
                        
                        Button("Hide Controls") {
                            withAnimation {
                                showControls = false
                            }
                        }
                    }
                    
                    // Speed control
                    HStack {
                        Text("Speed:")
                        Slider(value: $playbackSpeed, in: 0.1...3.0, step: 0.1)
                        Text(String(format: "%.1fx", playbackSpeed))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
            }
        }
        .background(Color.black)
        .onTapGesture {
            if !showControls {
                withAnimation {
                    showControls = true
                }
            }
        }
    }
    
    private var currentPoseKeypoints: [CGPoint] {
        guard currentFrame < swingFrames.count else { return [] }
        return swingFrames[currentFrame].keypoints
    }
}

// MARK: - Preview

struct ThreeDModelView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty 3D view
            ThreeDModelView()
                .previewDisplayName("Empty 3D View")
            
            // With sample data
            ThreeDModelView(
                poseKeypoints: sampleKeypoints,
                showSkeleton: true,
                showTrajectory: false
            )
            .previewDisplayName("With Skeleton")
            
            // Swing analysis view
            SwingAnalysis3DView(swingFrames: sampleSwingFrames)
                .previewDisplayName("Swing Analysis 3D")
        }
    }
    
    static var sampleKeypoints: [CGPoint] {
        [
            CGPoint(x: 0.5, y: 0.1),   // Nose
            CGPoint(x: 0.48, y: 0.12), // Left eye
            CGPoint(x: 0.52, y: 0.12), // Right eye
            CGPoint(x: 0.45, y: 0.15), // Left ear
            CGPoint(x: 0.55, y: 0.15), // Right ear
            CGPoint(x: 0.4, y: 0.3),   // Left shoulder
            CGPoint(x: 0.6, y: 0.3),   // Right shoulder
            CGPoint(x: 0.35, y: 0.5),  // Left elbow
            CGPoint(x: 0.65, y: 0.5),  // Right elbow
            CGPoint(x: 0.3, y: 0.7),   // Left wrist
            CGPoint(x: 0.7, y: 0.7),   // Right wrist
            CGPoint(x: 0.45, y: 0.6),  // Left hip
            CGPoint(x: 0.55, y: 0.6),  // Right hip
            CGPoint(x: 0.42, y: 0.8),  // Left knee
            CGPoint(x: 0.58, y: 0.8),  // Right knee
            CGPoint(x: 0.4, y: 0.95),  // Left ankle
            CGPoint(x: 0.6, y: 0.95),  // Right ankle
        ]
    }
    
    static var sampleSwingFrames: [PoseFrame] {
        (0..<30).map { i in
            PoseFrame(
                keypoints: sampleKeypoints,
                confidences: Array(repeating: 0.8, count: sampleKeypoints.count),
                timestamp: Date(timeIntervalSinceNow: Double(i) / 30.0)
            )
        }
    }
}
