//
//  ExportView.swift
//  SwingIQ
//
//  Export view component for MediaPipe testing
//

import SwiftUI

struct ExportView: View {
    @ObservedObject var exportService: JSONExportService
    let analysisResults: [TestAnalysisResult]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                exportOptionsSection
                exportProgressSection
                lastExportSection
            }
            .navigationTitle("Export Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var exportOptionsSection: some View {
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
    }
    
    private var exportProgressSection: some View {
        Group {
            if exportService.isExporting {
                Section("Export Progress") {
                    ProgressView(value: exportService.exportProgress)
                    Text("Exporting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var lastExportSection: some View {
        Group {
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
    }
    
    // MARK: - Export Logic
    
    private func exportResults(format: ExportFormat) {
        Task {
            do {
                exportService.isExporting = true
                
                // Simulate export process
                for i in 0...10 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    await MainActor.run {
                        exportService.exportProgress = Double(i) / 10.0
                    }
                }
                
                await MainActor.run {
                    exportService.isExporting = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    exportService.isExporting = false
                    isPresented = false
                }
            }
        }
    }
}
