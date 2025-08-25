//
//  YouTubeRecommendationsView.swift
//  SwingIQ
//
//  Created by Amp on 7/29/25.
//

import SwiftUI

struct YouTubeRecommendationsView: View {
    let recommendations: [GolfYouTubeRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Recommended Videos")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(recommendations.count) videos")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if recommendations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No video recommendations available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                            YouTubeVideoCard(recommendation: recommendation)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct YouTubeVideoCard: View {
    let recommendation: GolfYouTubeRecommendation
    @State private var showingVideo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with play button overlay
            ZStack {
                AsyncImage(url: URL(string: recommendation.video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
                .frame(width: 180, height: 101)
                .clipped()
                .cornerRadius(8)
                
                // Play button overlay
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                
                // Category badge
                VStack {
                    HStack {
                        Spacer()
                        Text(recommendation.improvementArea.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor(for: recommendation.improvementArea))
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(6)
            }
            
            // Video info
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.video.snippet.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(recommendation.video.snippet.channelTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // Relevance score indicator
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < Int(recommendation.relevanceScore / 2) ? Color.yellow : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                    
                    Spacer()
                }
            }
            .frame(width: 180, alignment: .leading)
        }
        .onTapGesture {
            openYouTubeVideo()
        }
        .sheet(isPresented: $showingVideo) {
            YouTubeVideoPlayerView(videoURL: recommendation.video.youtubeURL)
        }
    }
    
    private func categoryColor(for category: GolfYouTubeRecommendation.ImprovementArea) -> Color {
        switch category {
        case .general:
            return Color.blue
        case .backswing:
            return Color.green
        case .downswing:
            return Color.purple
        case .tempo:
            return Color.orange
        case .balance:
            return Color.pink
        case .driving:
            return Color.red
        case .impact:
            return Color.yellow
        case .followThrough:
            return Color.mint
        case .setup:
            return Color.cyan
        case .shortGame:
            return Color.indigo
        case .putting:
            return Color.brown
        }
    }
    
    private func openYouTubeVideo() {
        // Try to open in YouTube app first, then fallback to Safari
        if let youtubeURL = URL(string: recommendation.video.youtubeURL.replacingOccurrences(of: "https://www.youtube.com/watch?v=", with: "youtube://")) {
            if UIApplication.shared.canOpenURL(youtubeURL) {
                UIApplication.shared.open(youtubeURL)
                return
            }
        }
        
        // Fallback to web browser
        if let webURL = URL(string: recommendation.video.youtubeURL) {
            UIApplication.shared.open(webURL)
        }
    }
}

struct YouTubeVideoPlayerView: View {
    let videoURL: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            WebView(url: URL(string: videoURL)!)
                .navigationTitle("YouTube Video")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
    }
}

// Simple WebView for YouTube videos
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Preview

struct YouTubeRecommendationsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            YouTubeRecommendationsView(recommendations: [
                GolfYouTubeRecommendation(
                    video: YouTubeVideo(
                        videoId: YouTubeVideo.VideoId(videoId: "dQw4w9WgXcQ"),
                        snippet: VideoSnippet(
                            title: "Fix Your Swing Path with This Simple Drill",
                            description: "Learn how to fix your inside-out swing path with this easy drill",
                            channelTitle: "Rick Shiels Golf",
                            publishedAt: "2023-01-01T00:00:00Z",
                            thumbnails: VideoSnippet.Thumbnails(
                                default: VideoSnippet.Thumbnails.Thumbnail(url: "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg", width: 320, height: 180),
                                medium: VideoSnippet.Thumbnails.Thumbnail(url: "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg", width: 320, height: 180),
                                high: nil
                            )
                        )
                    ),
                    relevanceScore: 8.5,
                    improvementArea: .general,
                    reason: "This video addresses your swing path issues."
                ),
                GolfYouTubeRecommendation(
                    video: YouTubeVideo(
                        videoId: YouTubeVideo.VideoId(videoId: "dQw4w9WgXcQ2"),
                        snippet: VideoSnippet(
                            title: "Perfect Your Swing Plane",
                            description: "Master the correct swing plane for more consistent shots",
                            channelTitle: "Golf Digest",
                            publishedAt: "2023-01-01T00:00:00Z",
                            thumbnails: VideoSnippet.Thumbnails(
                                default: VideoSnippet.Thumbnails.Thumbnail(url: "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg", width: 320, height: 180),
                                medium: VideoSnippet.Thumbnails.Thumbnail(url: "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg", width: 320, height: 180),
                                high: nil
                            )
                        )
                    ),
                    relevanceScore: 9.2,
                    improvementArea: .backswing,
                    reason: "This video helps with swing plane improvements."
                )
            ])
        }
    }
}
