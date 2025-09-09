# SwingIQ iOS Agent Guide

## Build/Test Commands
- **Build**: `xcodebuild -workspace SwingIQ.xcworkspace -scheme SwingIQ build`
- **Test all**: `xcodebuild -workspace SwingIQ.xcworkspace -scheme SwingIQ test`
- **Test single file**: `xcodebuild -workspace SwingIQ.xcworkspace -scheme SwingIQ test -only-testing:SwingIQTests/SwingIQTests/testName`
- **Install pods**: `pod install` (required after Podfile changes)
- **Clean build**: `xcodebuild clean -workspace SwingIQ.xcworkspace -scheme SwingIQ`
- **API keys**: Configure in Info.plist (GEMINI_API_KEY, YOUTUBE_API_KEY optional)

## Architecture
- **iOS 16.0+ SwiftUI app** with TabView-based navigation (Home, Record, Stats, Settings)
- **Core services**: CameraService, MediaPipeService (pose detection), AIAnalysisService (Gemini API), YouTubeService
- **Data flow**: Camera → MediaPipe → AI Analysis → SwiftData storage → UI visualization
- **Dependencies**: MediaPipeTasksVision (CocoaPods), SwiftData for persistence
- **Key models**: SwingModels.swift (PoseFrame, SwingAnalysis), ExportModels.swift

## Code Style
- **Files**: CamelCase types, descriptive names ending with suffix (Service, View, Agent)
- **Variables**: camelCase, descriptive names, boolean prefixes (is, has, should)
- **Enums**: lowercase camelCase cases, String raw values for UI display
- **Imports**: Foundation first, then Apple frameworks, @testable for tests
- **MARK comments**: Extensive use for organization (// MARK: - Section Name)
- **Error handling**: Custom Error enums, AlertError struct for UI errors, graceful degradation
- **Testing**: Swift Testing framework (@Test), descriptive test names, Arrange-Act-Assert pattern
- **SwiftUI**: Property wrappers first, private properties, computed properties last
- **Logging**: Structured with emoji prefixes (📹, ⚠️, ℹ️) for visual distinction
