//
//  SwingDetectionService.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import Foundation
import CoreMotion
import AVFoundation

class SwingDetectionService: ObservableObject {
    @Published var autoTriggerEnabled: Bool = true
    @Published var sensitivityLevel: SensitivityLevel = .medium
    @Published var isDetecting: Bool = false
    
    private let motionManager = CMMotionManager()
    var onSwingDetected: (() -> Void)?
    private var accelerationThreshold: Double = 2.5
    private var swingStartTime: Date?
    private var isInSwing: Bool = false
    
    enum SensitivityLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        
        var threshold: Double {
            switch self {
            case .low: return 3.0
            case .medium: return 2.5
            case .high: return 2.0
            }
        }
    }
    
    init() {
        setupMotionDetection()
    }
    
    deinit {
        stopDetection()
    }
    
    // MARK: - Public Methods
    
    func startDetection() {
        print("🏌️ SwingDetectionService: startDetection called")
        guard autoTriggerEnabled && motionManager.isAccelerometerAvailable else { 
            print("🏌️ SwingDetectionService: Auto trigger disabled or accelerometer unavailable")
            return 
        }
        
        isDetecting = true
        accelerationThreshold = sensitivityLevel.threshold
        
        print("🏌️ SwingDetectionService: Starting accelerometer updates...")
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { 
                if let error = error {
                    print("❌ SwingDetectionService: Accelerometer error: \(error)")
                }
                return 
            }
            self.processAccelerometerData(data)
        }
        print("🏌️ SwingDetectionService: Detection started successfully")
    }
    
    func stopDetection() {
        isDetecting = false
        motionManager.stopAccelerometerUpdates()
        isInSwing = false
        swingStartTime = nil
    }
    
    func setSwingDetectedCallback(_ callback: @escaping () -> Void) {
        onSwingDetected = callback
    }
    
    // MARK: - Private Methods
    
    private func setupMotionDetection() {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ Accelerometer not available")
            return
        }
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = sqrt(data.acceleration.x * data.acceleration.x +
                              data.acceleration.y * data.acceleration.y +
                              data.acceleration.z * data.acceleration.z)
        
        // Detect swing start (takeaway)
        if !isInSwing && acceleration > accelerationThreshold {
            swingStartTime = Date()
            isInSwing = true
            print("🏌️ Swing takeaway detected - acceleration: \(acceleration)")
        }
        
        // Detect swing completion (follow through)
        if isInSwing, let startTime = swingStartTime {
            let swingDuration = Date().timeIntervalSince(startTime)
            
            // Typical golf swing is 1-3 seconds
            if swingDuration > 1.0 && acceleration < (accelerationThreshold * 0.5) {
                completeSwingDetection()
            }
            
            // Auto-complete after max swing time
            if swingDuration > 5.0 {
                completeSwingDetection()
            }
        }
    }
    
    private func completeSwingDetection() {
        guard isInSwing else { return }
        
        isInSwing = false
        let swingDuration = swingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        swingStartTime = nil
        
        print("🏌️ Swing completed - duration: \(swingDuration)s")
        
        // Delay before calling callback to ensure swing is fully complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.onSwingDetected?()
        }
    }
}

// MARK: - Convenience Init

extension SwingDetectionService {
    convenience init(onSwingDetected: @escaping () -> Void) {
        self.init()
        self.onSwingDetected = onSwingDetected
    }
}
