//
//  SwingAnalysis3DView.swift
//  SwingIQ
//
//  Created by Amp on 7/23/25.
//

import SwiftUI
import SceneKit

struct SwingPose3DView: View {
    let poseData: [PoseFrameData]
    @Binding var currentTime: Double
    let duration: Double
    
    @State private var scene: SCNScene?
    @State private var cameraNode: SCNNode?
    @State private var golferNode: SCNNode?
    @State private var swingPathNode: SCNNode?
    @State private var isPlaying = false
    @State private var animationSpeed: Double = 1.0
    @State private var viewAngle: ViewAngle = .front
    @State private var showSwingPath = true
    @State private var showGroundPlane = true
    
    enum ViewAngle: String, CaseIterable {
        case front = "Front"
        case side = "Side"
        case top = "Top"
        case free = "Free"
        
        var icon: String {
            switch self {
            case .front: return "person.fill"
            case .side: return "person.crop.square.fill"
            case .top: return "person.crop.circle.fill"
            case .free: return "rotate.3d"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 3D Scene View
            if let scene = scene {
                SceneView(
                    scene: scene,
                    pointOfView: cameraNode,
                    options: [.allowsCameraControl, .autoenablesDefaultLighting]
                )
                .background(Color.black)
            } else {
                loadingView
            }
            
            // 3D Controls Overlay
            VStack {
                // Top controls
                HStack {
                    // View angle selector
                    viewAngleSelector
                    
                    Spacer()
                    
                    // 3D toggles
                    threeDToggles
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Bottom time controls
                timeControlsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            setup3DScene()
        }
        .onChange(of: currentTime) { _ in
            updateGolferPose()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading 3D Analysis...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - View Angle Selector
    
    private var viewAngleSelector: some View {
        HStack(spacing: 8) {
            ForEach(ViewAngle.allCases, id: \.self) { angle in
                Button(action: {
                    viewAngle = angle
                    updateCameraPosition()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: angle.icon)
                            .font(.system(size: 12))
                        
                        Text(angle.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(viewAngle == angle ? .black : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewAngle == angle ? .white : Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - 3D Toggles
    
    private var threeDToggles: some View {
        HStack(spacing: 12) {
            Toggle3D(
                title: "Swing Path",
                icon: "scribble.variable",
                isOn: $showSwingPath
            ) {
                toggleSwingPath()
            }
            
            Toggle3D(
                title: "Ground",
                icon: "rectangle.grid.1x2",
                isOn: $showGroundPlane
            ) {
                toggleGroundPlane()
            }
        }
    }
    
    // MARK: - Time Controls Section
    
    private var timeControlsSection: some View {
        VStack(spacing: 12) {
            // Time scrubber
            VStack(spacing: 4) {
                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Slider(value: $currentTime, in: 0...duration)
                    .accentColor(Color(hex: "00B04F"))
            }
            
            // Animation controls
            HStack(spacing: 16) {
                // Speed control
                HStack(spacing: 4) {
                    Text("Speed:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Slider(value: $animationSpeed, in: 0.1...3.0, step: 0.1)
                        .frame(width: 60)
                        .accentColor(Color(hex: "00B04F"))
                    
                    Text(String(format: "%.1fx", animationSpeed))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 30)
                }
                
                Spacer()
                
                // Play controls
                HStack(spacing: 12) {
                    Button(action: seekToBeginning) {
                        Image(systemName: "backward.end.fill")
                            .foregroundColor(.white)
                    }
                    
                    Button(action: toggleAnimation) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: seekToEnd) {
                        Image(systemName: "forward.end.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    // MARK: - 3D Scene Setup
    
    private func setup3DScene() {
        scene = SCNScene()
        guard let scene = scene else { return }
        
        // Setup camera
        setupCamera(scene: scene)
        
        // Setup lighting
        setupLighting(scene: scene)
        
        // Setup ground plane
        setupGroundPlane(scene: scene)
        
        // Setup golfer skeleton
        setupGolferSkeleton(scene: scene)
        
        // Setup swing path
        setupSwingPath(scene: scene)
        
        // Initial pose update
        updateGolferPose()
    }
    
    private func setupCamera(scene: SCNScene) {
        cameraNode = SCNNode()
        cameraNode?.camera = SCNCamera()
        cameraNode?.position = SCNVector3(x: 0, y: 1.5, z: 3)
        cameraNode?.look(at: SCNVector3(x: 0, y: 1, z: 0))
        scene.rootNode.addChildNode(cameraNode!)
        
        updateCameraPosition()
    }
    
    private func setupLighting(scene: SCNScene) {
        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        scene.rootNode.addChildNode(ambientLight)
        
        // Directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(x: 2, y: 3, z: 2)
        directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(directionalLight)
    }
    
    private func setupGroundPlane(scene: SCNScene) {
        let groundGeometry = SCNPlane(width: 10, height: 10)
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.3)
        groundMaterial.isDoubleSided = true
        groundGeometry.materials = [groundMaterial]
        
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -Float.pi/2)
        groundNode.name = "ground"
        scene.rootNode.addChildNode(groundNode)
    }
    
    private func setupGolferSkeleton(scene: SCNScene) {
        golferNode = SCNNode()
        golferNode?.name = "golfer"
        scene.rootNode.addChildNode(golferNode!)
        
        // Create skeleton bones
        createSkeletonBones()
    }
    
    private func setupSwingPath(scene: SCNScene) {
        swingPathNode = SCNNode()
        swingPathNode?.name = "swingPath"
        scene.rootNode.addChildNode(swingPathNode!)
        
        // Create swing path visualization
        createSwingPath()
    }
    
    private func createSkeletonBones() {
        guard let golferNode = golferNode else { return }
        
        // Remove existing bones
        golferNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Define bone connections for golf swing analysis
        let connections: [(String, Int, Int, UIColor)] = [
            ("leftArm1", 11, 13, .systemRed),     // Left shoulder to elbow
            ("leftArm2", 13, 15, .systemRed),     // Left elbow to wrist
            ("rightArm1", 12, 14, .systemBlue),   // Right shoulder to elbow
            ("rightArm2", 14, 16, .systemBlue),   // Right elbow to wrist
            ("shoulders", 11, 12, .systemGreen),   // Shoulders
            ("leftTorso", 11, 23, .systemGreen),  // Left shoulder to hip
            ("rightTorso", 12, 24, .systemGreen), // Right shoulder to hip
            ("hips", 23, 24, .systemGreen),       // Hips
            ("leftLeg1", 23, 25, .systemPurple),  // Left hip to knee
            ("leftLeg2", 25, 27, .systemPurple),  // Left knee to ankle
            ("rightLeg1", 24, 26, .systemPurple), // Right hip to knee
            ("rightLeg2", 26, 28, .systemPurple)  // Right knee to ankle
        ]
        
        for (name, startIdx, endIdx, color) in connections {
            let boneGeometry = SCNCylinder(radius: 0.01, height: 1.0)
            let boneMaterial = SCNMaterial()
            boneMaterial.diffuse.contents = color
            boneGeometry.materials = [boneMaterial]
            
            let boneNode = SCNNode(geometry: boneGeometry)
            boneNode.name = name
            golferNode.addChildNode(boneNode)
        }
        
        // Create joint spheres
        for i in [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28] {
            let jointGeometry = SCNSphere(radius: 0.02)
            let jointMaterial = SCNMaterial()
            jointMaterial.diffuse.contents = UIColor.systemYellow
            jointGeometry.materials = [jointMaterial]
            
            let jointNode = SCNNode(geometry: jointGeometry)
            jointNode.name = "joint\(i)"
            golferNode.addChildNode(jointNode)
        }
    }
    
    private func createSwingPath() {
        guard let swingPathNode = swingPathNode else { return }
        
        // Remove existing path
        swingPathNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Create path from right wrist positions (index 16 in pose data)
        var pathPoints: [SCNVector3] = []
        
        for frame in poseData {
            if frame.keypoints.count > 16 {
                let wristPoint = frame.keypoints[16]
                // Convert 2D screen coordinates to 3D world coordinates
                let worldPoint = SCNVector3(
                    x: Float((wristPoint.x - 0.5) * 2), // Center and scale
                    y: Float((0.5 - wristPoint.y) * 2), // Flip Y and scale
                    z: 0
                )
                pathPoints.append(worldPoint)
            }
        }
        
        // Create path geometry
        if pathPoints.count > 1 {
            let pathGeometry = createPathGeometry(points: pathPoints)
            let pathMaterial = SCNMaterial()
            pathMaterial.diffuse.contents = UIColor.systemOrange
            pathGeometry.materials = [pathMaterial]
            
            let pathNode = SCNNode(geometry: pathGeometry)
            swingPathNode.addChildNode(pathNode)
        }
    }
    
    private func createPathGeometry(points: [SCNVector3]) -> SCNGeometry {
        // Create a path using connected cylinders
        let pathNode = SCNNode()
        
        for i in 0..<points.count - 1 {
            let start = points[i]
            let end = points[i + 1]
            
            let distance = start.distance(to: end)
            let segmentGeometry = SCNCylinder(radius: 0.005, height: CGFloat(distance))
            let segmentNode = SCNNode(geometry: segmentGeometry)
            
            // Position and orient the segment
            let midPoint = SCNVector3(
                x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2,
                z: (start.z + end.z) / 2
            )
            segmentNode.position = midPoint
            
            // Calculate rotation to align with segment direction
            let direction = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
            let up = SCNVector3(0, 1, 0)
            let rotationAxis = up.cross(direction).normalized()
            let angle = acos(up.dot(direction.normalized()))
            
            segmentNode.rotation = SCNVector4(rotationAxis.x, rotationAxis.y, rotationAxis.z, angle)
            
            pathNode.addChildNode(segmentNode)
        }
        
        return pathNode.geometry ?? SCNGeometry()
    }
    
    // MARK: - Animation and Updates
    
    private func updateGolferPose() {
        guard let golferNode = golferNode,
              !poseData.isEmpty else { return }
        
        // Find current frame based on time
        let frameIndex = Int((currentTime / duration) * Double(poseData.count - 1))
        let clampedIndex = max(0, min(frameIndex, poseData.count - 1))
        let currentFrame = poseData[clampedIndex]
        
        // Update joint positions
        for i in [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28] {
            if let jointNode = golferNode.childNode(withName: "joint\(i)", recursively: false),
               i < currentFrame.keypoints.count {
                let keypoint = currentFrame.keypoints[i]
                jointNode.position = SCNVector3(
                    x: Float((keypoint.x - 0.5) * 2),
                    y: Float((0.5 - keypoint.y) * 2),
                    z: 0
                )
            }
        }
        
        // Update bone positions and orientations
        updateBones(frame: currentFrame)
    }
    
    private func updateBones(frame: PoseFrameData) {
        guard let golferNode = golferNode else { return }
        
        let connections: [(String, Int, Int)] = [
            ("leftArm1", 11, 13), ("leftArm2", 13, 15),
            ("rightArm1", 12, 14), ("rightArm2", 14, 16),
            ("shoulders", 11, 12), ("leftTorso", 11, 23),
            ("rightTorso", 12, 24), ("hips", 23, 24),
            ("leftLeg1", 23, 25), ("leftLeg2", 25, 27),
            ("rightLeg1", 24, 26), ("rightLeg2", 26, 28)
        ]
        
        for (boneName, startIdx, endIdx) in connections {
            if let boneNode = golferNode.childNode(withName: boneName, recursively: false),
               startIdx < frame.keypoints.count && endIdx < frame.keypoints.count {
                
                let startPoint = frame.keypoints[startIdx]
                let endPoint = frame.keypoints[endIdx]
                
                let start3D = SCNVector3(
                    x: Float((startPoint.x - 0.5) * 2),
                    y: Float((0.5 - startPoint.y) * 2),
                    z: 0
                )
                let end3D = SCNVector3(
                    x: Float((endPoint.x - 0.5) * 2),
                    y: Float((0.5 - endPoint.y) * 2),
                    z: 0
                )
                
                // Position bone at midpoint
                boneNode.position = SCNVector3(
                    x: (start3D.x + end3D.x) / 2,
                    y: (start3D.y + end3D.y) / 2,
                    z: (start3D.z + end3D.z) / 2
                )
                
                // Scale bone to distance
                let distance = start3D.distance(to: end3D)
                boneNode.scale = SCNVector3(1, distance, 1)
                
                // Rotate bone to align with connection
                let direction = SCNVector3(
                    end3D.x - start3D.x,
                    end3D.y - start3D.y,
                    end3D.z - start3D.z
                ).normalized()
                
                let up = SCNVector3(0, 1, 0)
                let rotationAxis = up.cross(direction).normalized()
                let angle = acos(up.dot(direction))
                
                boneNode.rotation = SCNVector4(rotationAxis.x, rotationAxis.y, rotationAxis.z, angle)
            }
        }
    }
    
    private func updateCameraPosition() {
        guard let cameraNode = cameraNode else { return }
        
        switch viewAngle {
        case .front:
            cameraNode.position = SCNVector3(x: 0, y: 1.5, z: 3)
            cameraNode.look(at: SCNVector3(x: 0, y: 1, z: 0))
        case .side:
            cameraNode.position = SCNVector3(x: 3, y: 1.5, z: 0)
            cameraNode.look(at: SCNVector3(x: 0, y: 1, z: 0))
        case .top:
            cameraNode.position = SCNVector3(x: 0, y: 4, z: 0)
            cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        case .free:
            // Allow free camera control
            break
        }
    }
    
    // MARK: - Controls
    
    private func toggleAnimation() {
        isPlaying.toggle()
        
        if isPlaying {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // Implement smooth animation through frames
        // This would create a timer that updates currentTime automatically
    }
    
    private func stopAnimation() {
        // Stop the animation timer
    }
    
    private func seekToBeginning() {
        currentTime = 0
    }
    
    private func seekToEnd() {
        currentTime = duration
    }
    
    private func toggleSwingPath() {
        swingPathNode?.isHidden = !showSwingPath
    }
    
    private func toggleGroundPlane() {
        scene?.rootNode.childNode(withName: "ground", recursively: false)?.isHidden = !showGroundPlane
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct Toggle3D: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            isOn.toggle()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isOn ? .black : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOn ? .white : Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - SceneKit Extensions

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        let dx = x - vector.x
        let dy = y - vector.y
        let dz = z - vector.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    func normalized() -> SCNVector3 {
        let length = sqrt(x*x + y*y + z*z)
        return SCNVector3(x/length, y/length, z/length)
    }
    
    func cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            y * vector.z - z * vector.y,
            z * vector.x - x * vector.z,
            x * vector.y - y * vector.x
        )
    }
    
    func dot(_ vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
    }
}


