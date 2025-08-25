//
//  CameraService.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isCameraAuthorized = false
    @Published var showAlert = false
    @Published var alertError = AlertError()
    @Published var capturedImage: UIImage?
    @Published var recordedVideoURL: URL?
    
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    
    // Delegate for real-time video frame processing
    weak var frameDelegate: CameraFrameDelegate?
    
    // Callback for when recording completes
    var onRecordingCompleted: ((URL) -> Void)?
    
    override init() {
        super.init()
        print("📹 CameraService: Starting initialization...")
        checkCameraPermission()
        print("📹 CameraService: Initialization completed. Authorized: \(isCameraAuthorized)")
    }
    
    // MARK: - Camera Permission
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupSession()
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.sessionQueue.resume()
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
            showAlert = true
            alertError = AlertError(title: "Camera Access Denied", 
                                  message: "Please enable camera access in Settings to analyze your golf swing.")
        @unknown default:
            isCameraAuthorized = false
        }
    }
    
    // MARK: - Session Setup
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        guard isCameraAuthorized else { 
            print("📹 CameraService: Cannot configure session - not authorized")
            return 
        }
        
        print("📹 CameraService: Starting session configuration...")
        session.beginConfiguration()
        
        // Clear existing inputs and outputs first
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        session.sessionPreset = .high
        
        // Add video input
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                session.commitConfiguration()
                showError("Unable to access back camera")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
                print("📹 CameraService: Video input added successfully")
            } else {
                session.commitConfiguration()
                showError("Cannot add video input to session")
                return
            }
        } catch {
            session.commitConfiguration()
            showError("Unable to create camera input: \(error.localizedDescription)")
            return
        }
        
        // Add video output for real-time processing
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
            
            // Configure video settings for optimal performance
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            
            // Configure connection
            if let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 90 // Portrait mode (90 degrees rotation)
                } else {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            print("📹 CameraService: Video output configured successfully")
        } else {
            session.commitConfiguration()
            showError("Cannot add video output to session")
            return
        }
        
        // Add movie output for recording
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            print("📹 CameraService: Movie output added successfully")
        } else {
            print("📹 CameraService: Warning - Cannot add movie output")
        }
        
        session.commitConfiguration()
        print("📹 CameraService: Session configuration completed successfully")
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard isCameraAuthorized else {
            print("📹 CameraService: Cannot start session - not authorized")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard !self.session.isRunning else {
                print("📹 CameraService: Session already running")
                return
            }
            
            print("📹 CameraService: Starting session...")
            self.session.startRunning()
            print("📹 CameraService: Session started successfully")
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard self.session.isRunning else {
                print("📹 CameraService: Session not running")
                return
            }
            
            print("📹 CameraService: Stopping session...")
            self.session.stopRunning()
            print("📹 CameraService: Session stopped")
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        print("📹 CameraService: startRecording called")
        guard !isRecording else { 
            print("📹 CameraService: Already recording, returning")
            return 
        }
        
        guard session.isRunning else {
            print("❌ CameraService: Session not running, cannot start recording")
            showError("Camera session not running. Please restart the app.")
            return
        }
        
        guard movieOutput.isRecording == false else {
            print("❌ CameraService: Movie output already recording")
            return
        }
        
        print("📹 CameraService: Creating output URL...")
        let outputURL = createVideoOutputURL()
        print("📹 CameraService: Starting recording to: \(outputURL)")
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        DispatchQueue.main.async {
            print("📹 CameraService: Setting isRecording = true")
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        movieOutput.stopRecording()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    private func createVideoOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("swing_\(Date().timeIntervalSince1970).mov")
        
        // Remove file if it already exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        return outputURL
    }
    
    // MARK: - Camera Controls
    
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }
            
            // Get the new camera
            let newCameraPosition: AVCaptureDevice.Position = 
                self.currentInput?.device.position == .back ? .front : .back
            
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                         for: .video, 
                                                         position: newCameraPosition) else {
                self.session.commitConfiguration()
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentInput = newInput
                }
            } catch {
                self.showError("Unable to flip camera: \(error.localizedDescription)")
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func capturePhoto() {
        // For now, we'll capture from the video stream
        // In production, you might want to use AVCapturePhotoOutput for higher quality
        // The current video frame will be captured via the delegate
    }
    
    // MARK: - Focus and Exposure
    
    func setFocusAndExposure(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.currentInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
            } catch {
                self?.showError("Unable to set focus: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.alertError = AlertError(title: "Camera Error", message: message)
            self.showAlert = true
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Pass the frame to the delegate for real-time processing
        frameDelegate?.didReceiveFrame(sampleBuffer)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.showError("Recording failed: \(error.localizedDescription)")
            } else {
                self.recordedVideoURL = outputFileURL
                self.onRecordingCompleted?(outputFileURL)
            }
        }
    }
}

// MARK: - Supporting Types

protocol CameraFrameDelegate: AnyObject {
    func didReceiveFrame(_ sampleBuffer: CMSampleBuffer)
}

struct AlertError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    
    init(title: String = "Error", message: String = "") {
        self.title = title
        self.message = message
    }
}

// MARK: - Camera Preview

/// A UIView whose layerClass is AVCaptureVideoPreviewLayer.
/// This removes the need to manage a sublayer manually.
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer? { layer as? AVCaptureVideoPreviewLayer }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        print("📹 CameraPreview: Creating PreviewView")
        let view = PreviewView()
        view.backgroundColor = .black
        
        if let previewLayer = view.previewLayer {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.backgroundColor = UIColor.black.cgColor
        } else {
            print("❌ Failed to get preview layer from PreviewView")
        }
        
        // Add debug info
        print("📹 CameraPreview: Session running: \(session.isRunning)")
        print("📹 CameraPreview: Session inputs: \(session.inputs.count)")
        print("📹 CameraPreview: Session outputs: \(session.outputs.count)")
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Already on main thread – no extra dispatch needed
        uiView.previewLayer?.frame = uiView.bounds
    }
}
