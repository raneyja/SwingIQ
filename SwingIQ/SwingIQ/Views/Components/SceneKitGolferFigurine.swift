//
//  SceneKitGolferFigurine.swift
//  SwingIQ
//
//  3D Golfer figurine using SceneKit
//

import SwiftUI
import SceneKit

struct SceneKitGolferFigurine: UIViewRepresentable {
    
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
        
        // Create golfer figure
        let golferNode = createGolferFigure()
        scene.rootNode.addChildNode(golferNode)
        
        // Add golf club
        let clubNode = createGolfClub()
        golferNode.addChildNode(clubNode)
        
        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 8)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private func createGolferFigure() -> SCNNode {
        let golferNode = SCNNode()
        
        // Head
        let head = SCNSphere(radius: 0.3)
        head.firstMaterial?.diffuse.contents = UIColor.systemGray4
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 2.5, 0)
        golferNode.addChildNode(headNode)
        
        // Torso
        let torso = SCNCylinder(radius: 0.4, height: 1.2)
        torso.firstMaterial?.diffuse.contents = UIColor.systemGray3
        let torsoNode = SCNNode(geometry: torso)
        torsoNode.position = SCNVector3(0, 1.5, 0)
        torsoNode.rotation = SCNVector4(0, 0, 1, Float.pi * 0.1) // Slight rotation for follow-through
        golferNode.addChildNode(torsoNode)
        
        // Arms (simplified)
        createArm(parent: golferNode, side: "left", x: -0.5, rotation: -0.3)
        createArm(parent: golferNode, side: "right", x: 0.5, rotation: 0.5)
        
        // Legs
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
        
        // Shaft
        let shaft = SCNCylinder(radius: 0.02, height: 3.0)
        shaft.firstMaterial?.diffuse.contents = UIColor.systemGray
        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.position = SCNVector3(0.8, 1.0, 0)
        shaftNode.rotation = SCNVector4(0, 0, 1, Float.pi * 0.3)
        clubNode.addChildNode(shaftNode)
        
        // Club head
        let head = SCNBox(width: 0.3, height: 0.1, length: 0.15, chamferRadius: 0.02)
        head.firstMaterial?.diffuse.contents = UIColor.darkGray
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(1.8, -0.3, 0)
        clubNode.addChildNode(headNode)
        
        return clubNode
    }
}

#Preview {
    SceneKitGolferFigurine()
        .frame(width: 200, height: 280)
        .background(Color.white)
}
