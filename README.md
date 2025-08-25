# SwingIQ - Golf Swing Analysis iOS App

SwingIQ is an iOS application that uses AI-powered pose detection and analysis to help golfers improve their swing technique through real-time feedback and detailed metrics.

## Features

- **Real-time Camera Analysis**: Capture and analyze golf swings in real-time using device camera
- **MediaPipe Pose Detection**: Advanced pose landmark detection for precise swing analysis
- **3D Visualization**: Interactive 3D models showing swing motion and key positions
- **Swing Phase Detection**: Automatic identification of setup, backswing, downswing, impact, and follow-through
- **Fault Detection**: AI-powered identification of common swing faults with corrective recommendations
- **Metrics Tracking**: Comprehensive swing metrics including clubhead speed, tempo, balance, and more
- **Video Processing**: Analyze recorded swing videos frame by frame
- **Data Export**: Export analysis results in JSON, CSV, and PDF formats

## Project Structure

```
SwingIQ/
├── SwingIQ/
│   ├── Agents/                 # AI analysis agents
│   │   └── SwingAnalyzerAgent.swift
│   ├── Analysis/               # Video and data processing
│   │   └── VideoProcessor.swift
│   ├── Models/                 # Data models and ML assets
│   │   ├── SwingModels.swift
│   │   ├── ExportModels.swift
│   │   └── pose_landmarker_full.task
│   ├── Services/               # Core services
│   │   ├── MediaPipeService.swift
│   │   ├── CameraService.swift
│   │   └── JSONExportService.swift
│   ├── Views/                  # UI components
│   │   ├── MediaPipeTestView.swift
│   │   └── ThreeDModelView.swift
│   ├── ContentView.swift       # Main navigation
│   └── SwingIQApp.swift       # App entry point
├── SwingIQTests/              # Unit tests
└── SwingIQUITests/            # UI tests
```

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Device with camera capability
- Minimum 2GB storage for ML models

## Installation

1. Clone the repository
2. Open `SwingIQ.xcodeproj` in Xcode
3. Build and run on device or simulator

## Core Components

### MediaPipeService
Handles pose detection using Google's MediaPipe framework with the full pose landmarker model.

### SwingAnalyzerAgent
AI-powered analysis engine that processes pose data to:
- Detect swing phases
- Calculate performance metrics
- Identify swing faults
- Generate improvement recommendations

### CameraService
Manages camera permissions, session configuration, and real-time frame capture.

### VideoProcessor
Processes recorded videos for detailed frame-by-frame analysis.

## Usage

1. **Live Analysis**: Use the camera view to analyze swings in real-time
2. **Video Analysis**: Import existing videos for detailed analysis
3. **3D Visualization**: View swing motion in interactive 3D models
4. **Export Data**: Save analysis results for sharing or tracking progress

## Build Commands

```bash
# Build for simulator
xcodebuild -project SwingIQ.xcodeproj -scheme SwingIQ -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for device
xcodebuild -project SwingIQ.xcodeproj -scheme SwingIQ -destination 'generic/platform=iOS' build

# Run tests
xcodebuild test -project SwingIQ.xcodeproj -scheme SwingIQ -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Development Status

✅ Core architecture implemented  
✅ MediaPipe integration (placeholder)  
✅ Camera handling  
✅ Swing analysis framework  
✅ 3D visualization  
✅ Data export functionality  
✅ Navigation and UI structure  

🔄 Next Steps:
- Integrate actual MediaPipe Swift SDK
- Enhance swing analysis algorithms
- Improve UI/UX design
- Add comprehensive testing
- Performance optimization

## License

This project is proprietary software. All rights reserved.
