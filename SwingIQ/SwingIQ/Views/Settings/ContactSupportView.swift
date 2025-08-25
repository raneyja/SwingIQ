//
//  ContactSupportView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI
import MessageUI

struct ContactSupportView: View {
    @State private var supportType: SupportType = .general
    @State private var subject = ""
    @State private var message = ""
    @State private var includeSystemInfo = true
    @State private var includeLogs = false
    @State private var showingMailComposer = false
    @State private var showingShareSheet = false
    @State private var canSendMail = MFMailComposeViewController.canSendMail()
    
    enum SupportType: String, CaseIterable {
        case general = "General Question"
        case bug = "Bug Report"
        case feature = "Feature Request"
        case account = "Account Issue"
        case billing = "Billing Question"
        case technical = "Technical Support"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Method") {
                    if canSendMail {
                        Button(action: { showingMailComposer = true }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("Send Email")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Recommended")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Button(action: openSupportWebsite) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("Visit Support Website")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: callSupport) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.orange)
                            Text("Call Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Mon-Fri 9AM-5PM EST")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Quick Actions") {
                    NavigationLink(destination: BugReportView()) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Report a Bug")
                                Text("Found an issue? Let us know")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: FeatureRequestView()) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Request a Feature")
                                Text("Share your ideas for improvement")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: FeedbackView()) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("General Feedback")
                                Text("Tell us about your experience")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Support Resources") {
                    NavigationLink(destination: SystemInfoView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("System Information")
                        }
                    }
                    
                    Button(action: generateSupportBundle) {
                        HStack {
                            Image(systemName: "doc.zipper")
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)
                            Text("Generate Support Bundle")
                        }
                    }
                    
                    NavigationLink(destination: KnownIssuesView()) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            Text("Known Issues")
                        }
                    }
                }
                
                Section("Community") {
                    Button(action: openCommunityForum) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Community Forum")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: openSocialMedia) {
                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Follow Us on Social Media")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Response Time") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Email Support:")
                            Spacer()
                            Text("24-48 hours")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Bug Reports:")
                            Spacer()
                            Text("1-3 business days")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Feature Requests:")
                            Spacer()
                            Text("1-2 weeks")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    supportType: supportType,
                    subject: subject,
                    message: message,
                    includeSystemInfo: includeSystemInfo
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [generateSupportBundleContent()])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openSupportWebsite() {
        if let url = URL(string: "https://swingiq.com/support") {
            UIApplication.shared.open(url)
        }
    }
    
    private func callSupport() {
        if let url = URL(string: "tel:+1-555-SWING-IQ") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openCommunityForum() {
        if let url = URL(string: "https://community.swingiq.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSocialMedia() {
        if let url = URL(string: "https://twitter.com/SwingIQApp") {
            UIApplication.shared.open(url)
        }
    }
    
    private func generateSupportBundle() {
        showingShareSheet = true
    }
    
    private func generateSupportBundleContent() -> String {
        var content = "SwingIQ Support Bundle\n"
        content += "Generated: \(Date())\n\n"
        content += "Device: \(UIDevice.current.model)\n"
        content += "iOS Version: \(UIDevice.current.systemVersion)\n"
        content += "App Version: 1.0.0\n"
        content += "Build: 2025.07.19\n\n"
        content += "System Info:\n"
        content += "Free Storage: \(getAvailableStorage())\n"
        content += "Battery Level: \(UIDevice.current.batteryLevel * 100)%\n"
        return content
    }
    
    private func getAvailableStorage() -> String {
        let fileManager = FileManager.default
        do {
            let systemAttributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: freeSpace.int64Value)
            }
        } catch {
            return "Unknown"
        }
        return "Unknown"
    }
}

// MARK: - Supporting Views

struct BugReportView: View {
    @State private var bugTitle = ""
    @State private var bugDescription = ""
    @State private var stepsToReproduce = ""
    @State private var severity: BugSeverity = .medium
    @State private var category: BugCategory = .analysis
    
    enum BugSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    enum BugCategory: String, CaseIterable {
        case analysis = "Swing Analysis"
        case camera = "Camera/Recording"
        case ui = "User Interface"
        case performance = "Performance"
        case sync = "Data Sync"
        case other = "Other"
    }
    
    var body: some View {
        Form {
            Section("Bug Details") {
                TextField("Bug Title", text: $bugTitle)
                
                Picker("Category", selection: $category) {
                    ForEach(BugCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                
                Picker("Severity", selection: $severity) {
                    ForEach(BugSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(severity)
                    }
                }
            }
            
            Section("Description") {
                TextField("Describe the bug", text: $bugDescription, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Steps to Reproduce") {
                TextField("How can we reproduce this issue?", text: $stepsToReproduce, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section {
                Button("Submit Bug Report") {
                    submitBugReport()
                }
                .disabled(bugTitle.isEmpty || bugDescription.isEmpty)
            }
        }
        .navigationTitle("Report Bug")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitBugReport() {
        // Submit bug report
    }
}

struct FeatureRequestView: View {
    @State private var featureTitle = ""
    @State private var featureDescription = ""
    @State private var useCase = ""
    @State private var priority: FeaturePriority = .medium
    
    enum FeaturePriority: String, CaseIterable {
        case low = "Nice to Have"
        case medium = "Would be Helpful"
        case high = "Really Need This"
    }
    
    var body: some View {
        Form {
            Section("Feature Request") {
                TextField("Feature Title", text: $featureTitle)
                
                Picker("Priority", selection: $priority) {
                    ForEach(FeaturePriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
            }
            
            Section("Description") {
                TextField("Describe the feature you'd like", text: $featureDescription, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Use Case") {
                TextField("How would this feature help you?", text: $useCase, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section {
                Button("Submit Feature Request") {
                    submitFeatureRequest()
                }
                .disabled(featureTitle.isEmpty || featureDescription.isEmpty)
            }
        }
        .navigationTitle("Feature Request")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitFeatureRequest() {
        // Submit feature request
    }
}

struct FeedbackView: View {
    @State private var rating = 5
    @State private var feedback = ""
    @State private var category: FeedbackCategory = .general
    
    enum FeedbackCategory: String, CaseIterable {
        case general = "General"
        case usability = "Ease of Use"
        case features = "Features"
        case performance = "Performance"
        case design = "Design"
    }
    
    var body: some View {
        Form {
            Section("Overall Rating") {
                HStack {
                    Text("Rating:")
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                }
            }
            
            Section("Feedback Category") {
                Picker("Category", selection: $category) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }
            
            Section("Your Feedback") {
                TextField("Tell us what you think about SwingIQ", text: $feedback, axis: .vertical)
                    .lineLimit(4...8)
            }
            
            Section {
                Button("Submit Feedback") {
                    submitFeedback()
                }
                .disabled(feedback.isEmpty)
            }
        }
        .navigationTitle("Send Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitFeedback() {
        // Submit feedback
    }
}

struct SystemInfoView: View {
    var body: some View {
        List {
            Section("Device Information") {
                InfoRow(label: "Device", value: UIDevice.current.model)
                InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                InfoRow(label: "Device Name", value: UIDevice.current.name)
            }
            
            Section("App Information") {
                InfoRow(label: "App Version", value: "1.0.0")
                InfoRow(label: "Build Number", value: "2025.07.19")
                InfoRow(label: "Bundle ID", value: "com.swingiq.app")
            }
            
            Section("System Status") {
                InfoRow(label: "Available Storage", value: getAvailableStorage())
                InfoRow(label: "Battery Level", value: "\(Int(UIDevice.current.batteryLevel * 100))%")
                InfoRow(label: "Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
            }
            
            Section("Permissions") {
                InfoRow(label: "Camera Access", value: "Granted")
                InfoRow(label: "Microphone Access", value: "Granted")
                InfoRow(label: "Photo Library", value: "Granted")
            }
        }
        .navigationTitle("System Information")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getAvailableStorage() -> String {
        let fileManager = FileManager.default
        do {
            let systemAttributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: freeSpace.int64Value)
            }
        } catch {
            return "Unknown"
        }
        return "Unknown"
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct KnownIssuesView: View {
    var body: some View {
        List {
            Section("Current Known Issues") {
                KnownIssueRow(
                    title: "Camera lag on older devices",
                    description: "Users with iPhone X or older may experience camera lag during recording",
                    status: "Investigating",
                    statusColor: .orange
                )
                
                KnownIssueRow(
                    title: "iCloud sync delays",
                    description: "Data sync to iCloud may take longer than expected on slow connections",
                    status: "Fix in Progress",
                    statusColor: .blue
                )
            }
            
            Section("Recently Fixed") {
                KnownIssueRow(
                    title: "Analysis crashes with slow motion",
                    description: "App would crash when analyzing slow motion videos",
                    status: "Fixed in 1.0.0",
                    statusColor: .green
                )
            }
        }
        .navigationTitle("Known Issues")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KnownIssueRow: View {
    let title: String
    let description: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Text(status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Mail Composer

struct MailComposeView: UIViewControllerRepresentable {
    let supportType: ContactSupportView.SupportType
    let subject: String
    let message: String
    let includeSystemInfo: Bool
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["support@swingiq.com"])
        composer.setSubject("[\(supportType.rawValue)] \(subject)")
        
        var body = message
        if includeSystemInfo {
            body += "\n\n--- System Information ---\n"
            body += "Device: \(UIDevice.current.model)\n"
            body += "iOS: \(UIDevice.current.systemVersion)\n"
            body += "App Version: 1.0.0\n"
        }
        
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContactSupportView()
}
