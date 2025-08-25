//
//  MediaPipeTestView.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import SwiftUI
import AVFoundation

struct MediaPipeTestView: View {
    @StateObject private var mediaPipeService = MediaPipeService()
    @StateObject private var cameraService = CameraService()
    @StateObject private var swingAnalyzer = SwingAnalyzerAgent()
    @StateObject private var exportService = JSONExportService()
    
    @State private var isAnalyzing = false
    @State private var showingImagePicker = false
    @State private var showingSettings = false
    @State private var showingExport = false
    @State private var selectedImage: UIImage?
    @State private var analysisResults: [TestAnalysisResult] = []
    @State private var currentTab = 0
    @State private var frameProcessor: FrameProcessor?
    @State private var initializationError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if let error = initializationError {
                // Show initialization error
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Initialization Error")
                        .font(.headline)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        retryInitialization()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Custom segmented control instead of TabView
                Picker("Mode", selection: $currentTab) {
                    Text("Live").tag(0)
                    Text("Image").tag(1)
                    Text("Results").tag(2)
                    Text("3D View").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                Group {
                    switch currentTab {
                    case 0:
                        liveCameraTab
                    case 1:
                        imageAnalysisTab
                    case 2:
                        resultsTab
                    case 3:
                        threeDTab
                    default:
                        liveCameraTab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Settings") {
                    showingSettings = true
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Export") {
                    showingExport = true
                }
                .disabled(analysisResults.isEmpty)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingSettings) {
            settingsView
        }
        .sheet(isPresented: $showingExport) {
            exportView
        }
        .alert("Camera Error", isPresented: $cameraService.showAlert) {
            Button("OK") { }
        } message: {
            Text(cameraService.alertError.message)
        }
        .onAppear {
            print("📱 MediaPipeTestView: View appeared, starting initialization checks...")
            checkInitialization()
            setupCameraFrameDelegate()
            print("📱 MediaPipeTestView: Initialization complete. Error: \(initializationError ?? "None")")
        }
        .onDisappear {
            print("📱 MediaPipeTestView: View disappeared, cleaning up...")
            // Clear frame delegate to prevent crashes
            cameraService.frameDelegate = nil
            frameProcessor = nil
        }
    }
    
    // MARK: - Live Camera Tab
    
    private var liveCameraTab: some View {
        ZStack {
            if cameraService.isCameraAuthorized {
                CameraPreview(session: cameraService.session)
                    .onAppear {
                        cameraService.startSession()
                    }
                    .onDisappear {
                        cameraService.stopSession()
                    }
                
                // Overlay for pose visualization
                PoseOverlayView(keypoints: mediaPipeService.poseKeypoints)
                
                // Controls overlay
                VStack {
                    Spacer()
                    
                    liveCameraControls
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                }
            } else {
                cameraPermissionView
            }
        }
        .onAppear {
            // Ensure camera permission is checked when tab appears
            if !cameraService.isCameraAuthorized {
                cameraService.checkCameraPermission()
            }
        }
    }
    
    private var liveCameraControls: some View {
        VStack(spacing: 16) {
            // Status indicators
            HStack {
                statusIndicator(
                    title: "MediaPipe",
                    isActive: !mediaPipeService.isProcessing,
                    color: mediaPipeService.lastError == nil ? .green : .red
                )
                
                Spacer()
                
                statusIndicator(
                    title: "Recording",
                    isActive: cameraService.isRecording,
                    color: .red
                )
            }
            
            // Controls
            HStack(spacing: 20) {
                Button(action: cameraService.flipCamera) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    if cameraService.isRecording {
                        cameraService.stopRecording()
                    } else {
                        cameraService.startRecording()
                    }
                }) {
                    Image(systemName: cameraService.isRecording ? "stop.circle" : "record.circle")
                        .font(.title)
                        .foregroundColor(cameraService.isRecording ? .red : .white)
                }
                
                Button(action: cameraService.capturePhoto) {
                    Image(systemName: "camera.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            // Metrics display
            if !mediaPipeService.poseKeypoints.isEmpty {
                metricsDisplay
            }
        }
    }
    
    private var cameraPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.headline)
            
            Text("Please enable camera access in Settings to test MediaPipe pose detection.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Image Analysis Tab
    
    private var imageAnalysisTab: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                imageAnalysisView(image: image)
            } else {
                imagePlaceholderView
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var imagePlaceholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Select an Image")
                .font(.headline)
            
            Text("Choose an image to test pose detection")
                .foregroundColor(.secondary)
            
            Button("Select Image") {
                showingImagePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func imageAnalysisView(image: UIImage) -> some View {
        VStack(spacing: 16) {
            // Image with pose overlay
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                
                if !mediaPipeService.poseKeypoints.isEmpty {
                    PoseOverlayView(keypoints: mediaPipeService.poseKeypoints)
                        .frame(maxHeight: 300)
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Analysis controls
            HStack {
                Button("Analyze Pose") {
                    analyzeImage(image)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing)
                
                Button("New Image") {
                    selectedImage = nil
                    mediaPipeService.poseKeypoints = []
                }
                .buttonStyle(.bordered)
            }
            
            if isAnalyzing {
                ProgressView("Analyzing...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            // Results
            if !mediaPipeService.poseKeypoints.isEmpty {
                imageAnalysisResults
            }
        }
    }
    
    private var imageAnalysisResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Results")
                .font(.headline)
            
            analysisStatsGroup
            
            Divider()
            
            metricsDisplay
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var analysisStatsGroup: some View {
        Group {
            HStack {
                Text("Keypoints Detected:")
                Spacer()
                Text("\(mediaPipeService.poseKeypoints.count)")
                    .foregroundColor(.secondary)
            }
            
            confidenceRow
            
            HStack {
                Text("Swing Phase:")
                Spacer()
                Text(mediaPipeService.getSwingPhase().description)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var confidenceRow: some View {
        HStack {
            Text("Average Confidence:")
            Spacer()
            Text(confidenceText)
                .foregroundColor(.secondary)
        }
    }
    
    private var confidenceText: String {
        let avgConfidence = mediaPipeService.confidenceScores.isEmpty ? 0.0 : Double(mediaPipeService.confidenceScores.reduce(0.0, +)) / Double(mediaPipeService.confidenceScores.count)
        return String(format: "%.1f%%", avgConfidence * 100)
    }
    
    // MARK: - Results Tab
    
    private var resultsTab: some View {
        VStack {
            if analysisResults.isEmpty {
                emptyResultsView
            } else {
                resultsListView
            }
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Analysis Results")
                .font(.headline)
            
            Text("Capture images or record videos to see analysis results here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var resultsListView: some View {
        List {
            ForEach(analysisResults) { result in
                resultRow(result: result)
            }
            .onDelete(perform: deleteResults)
        }
        .navigationTitle("Analysis Results")
    }
    
    private func resultRow(result: TestAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Analysis")
                    .font(.headline)
                
                Spacer()
                
                Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Keypoints: \(result.keypointCount)")
                    Text("Confidence: \(String(format: "%.1f%%", result.averageConfidence * 100))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Phase: \(result.swingPhase)")
                    Text("Score: \(String(format: "%.1f", result.overallScore))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 3D Visualization Tab
    
    private var threeDTab: some View {
        VStack {
            if !mediaPipeService.poseKeypoints.isEmpty {
                ThreeDModelView(
                    poseKeypoints: mediaPipeService.poseKeypoints,
                    showSkeleton: true,
                    showTrajectory: false
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "cube")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Pose Data")
                        .font(.headline)
                    
                    Text("Analyze an image or use live camera to see 3D pose visualization.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Shared Components
    
    private var metricsDisplay: some View {
        let metrics = mediaPipeService.getSwingMetrics()
        
        return VStack(spacing: 8) {
            Text("Swing Metrics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {

                metricCard(title: "Tempo", value: metrics?.tempoFormatted ?? "N/A", color: .orange)
                metricCard(title: "Balance", value: metrics?.balanceFormatted ?? "N/A", color: .purple)
            }
        }
    }
    
    private func metricCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.3))
        .cornerRadius(8)
    }
    
    private func statusIndicator(title: String, isActive: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? color : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        NavigationView {
            List {
                Section("MediaPipe") {
                    if let error = mediaPipeService.lastError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    } else {
                        Label("Working correctly", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Camera") {
                    HStack {
                        Text("Authorization")
                        Spacer()
                        Text(cameraService.isCameraAuthorized ? "Granted" : "Denied")
                            .foregroundColor(cameraService.isCameraAuthorized ? .green : .red)
                    }
                }
                
                Section("Analysis") {
                    HStack {
                        Text("Total Results")
                        Spacer()
                        Text("\(analysisResults.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear All Results") {
                        analysisResults.removeAll()
                    }
                    .foregroundColor(.red)
                    .disabled(analysisResults.isEmpty)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Export View
    
    private var exportView: some View {
        NavigationView {
            List {
                Section("Export Options") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            exportResults(format: format)
                        }) {
                            HStack {
                                Text(format.displayName)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .disabled(exportService.isExporting)
                    }
                }
                
                if exportService.isExporting {
                    Section("Export Progress") {
                        ProgressView(value: exportService.exportProgress)
                        Text("Exporting...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let lastURL = exportService.lastExportURL {
                    Section("Last Export") {
                        ShareLink(item: lastURL) {
                            HStack {
                                Text("Share Last Export")
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingExport = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkInitialization() {
        // Check MediaPipe service initialization
        if let error = mediaPipeService.lastError {
            initializationError = "MediaPipe Error: \(error)"
            return
        }
        
        // Check if camera service has any critical issues
        if cameraService.showAlert && !cameraService.alertError.message.isEmpty {
            initializationError = "Camera Error: \(cameraService.alertError.message)"
            return
        }
        
        // All good, clear any previous errors
        initializationError = nil
    }
    
    private func retryInitialization() {
        initializationError = nil
        
        // Reinitialize services
        mediaPipeService.loadMediaPipeModel()
        cameraService.checkCameraPermission()
        
        // Recheck after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkInitialization()
        }
    }
    
    private func setupCameraFrameDelegate() {
        guard initializationError == nil else { 
            print("📱 MediaPipeTestView: Skipping frame delegate setup due to initialization error")
            return 
        }
        
        // Clear any existing delegate to prevent crashes
        cameraService.frameDelegate = nil
        
        frameProcessor = FrameProcessor(mediaPipeService: mediaPipeService, onAnalysis: handleRealtimeAnalysis)
        cameraService.frameDelegate = frameProcessor
        
        print("📱 MediaPipeTestView: Frame delegate setup completed")
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        mediaPipeService.detectPose(in: image) { [weak mediaPipeService] success in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                if success, let service = mediaPipeService {
                    let result = TestAnalysisResult(
                        timestamp: Date(),
                        keypointCount: service.poseKeypoints.count,
                        averageConfidence: service.confidenceScores.isEmpty ? 0.0 : Double(service.confidenceScores.reduce(0.0, +)) / Double(service.confidenceScores.count),
                        swingPhase: service.getSwingPhase().description,
                        metrics: service.getSwingMetrics() ?? SwingMetrics(tempo: 0, balance: 0, swingPathDeviation: 0),
                        overallScore: calculateOverallScore(service.getSwingMetrics() ?? SwingMetrics(tempo: 0, balance: 0, swingPathDeviation: 0))
                    )
                    
                    self.analysisResults.append(result)
                }
            }
        }
    }
    
    private func handleRealtimeAnalysis() {
        // Handle real-time analysis results
        // This could update UI or store data
    }
    
    private func calculateOverallScore(_ metrics: SwingMetrics) -> Double {
        // Simple scoring algorithm using reliable metrics only
        let tempoScore = min(100, max(0, (4.0 - abs(metrics.tempo - 3.0)) / 4.0 * 100)) // Ideal tempo around 3:1
        let balanceScore = metrics.balance * 100
        let pathScore = min(100, max(0, 100 - abs(metrics.swingPathDeviation) * 5)) // Penalize deviation
        
        return (tempoScore + balanceScore + pathScore) / 3.0
    }
    
    private func deleteResults(offsets: IndexSet) {
        analysisResults.remove(atOffsets: offsets)
    }
    
    private func exportResults(format: ExportFormat) {
        // This would export the test results
        // For now, we'll just show the export progress
        Task {
            do {
                // Simulate export
                exportService.isExporting = true
                
                for i in 0...10 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    await MainActor.run {
                        exportService.exportProgress = Double(i) / 10.0
                    }
                }
                
                await MainActor.run {
                    exportService.isExporting = false
                    showingExport = false
                }
            } catch {
                await MainActor.run {
                    exportService.isExporting = false
                    showingExport = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct TestAnalysisResult: Identifiable {
    let id = UUID()
    let timestamp: Date
    let keypointCount: Int
    let averageConfidence: Double
    let swingPhase: String
    let metrics: SwingMetrics
    let overallScore: Double
}

class FrameProcessor: CameraFrameDelegate {
    private let mediaPipeService: MediaPipeService
    private let onAnalysis: () -> Void
    private var frameCount = 0
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "frame.processing", qos: .userInitiated)
    private let serialQueue = DispatchQueue(label: "frame.serial", qos: .userInitiated)
    
    init(mediaPipeService: MediaPipeService, onAnalysis: @escaping () -> Void) {
        self.mediaPipeService = mediaPipeService
        self.onAnalysis = onAnalysis
    }
    
    func didReceiveFrame(_ sampleBuffer: CMSampleBuffer) {
        // Use serial queue to prevent race conditions
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Skip frames if already processing or not enough frames have passed
            self.frameCount += 1
            guard self.frameCount % 20 == 0, !self.isProcessing else { return }
            
            self.isProcessing = true
            
            // MediaPipe processing on main queue to ensure thread safety
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.mediaPipeService.detectPose(in: sampleBuffer) { [weak self] success in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        if success {
                            self.onAnalysis()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Pose Overlay View

struct PoseOverlayView: View {
    let keypoints: [CGPoint]
    
    var body: some View {
        Canvas { context, size in
            // Draw keypoints
            for keypoint in keypoints {
                let point = CGPoint(
                    x: keypoint.x * size.width,
                    y: keypoint.y * size.height
                )
                
                context.fill(
                    Path(ellipseIn: CGRect(
                        origin: CGPoint(x: point.x - 3, y: point.y - 3),
                        size: CGSize(width: 6, height: 6)
                    )),
                    with: .color(.red)
                )
            }
            
            // Draw connections (simplified skeleton)
            if keypoints.count >= 8 {
                drawConnection(context, size, from: keypoints[0], to: keypoints[1]) // Example connection
            }
        }
    }
    
    private func drawConnection(_ context: GraphicsContext, _ size: CGSize, from: CGPoint, to: CGPoint) {
        let fromPoint = CGPoint(x: from.x * size.width, y: from.y * size.height)
        let toPoint = CGPoint(x: to.x * size.width, y: to.y * size.height)
        
        var path = Path()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        
        context.stroke(path, with: .color(.white), lineWidth: 2)
    }
}

// MARK: - Preview

struct MediaPipeTestView_Previews: PreviewProvider {
    static var previews: some View {
        MediaPipeTestView()
    }
}
