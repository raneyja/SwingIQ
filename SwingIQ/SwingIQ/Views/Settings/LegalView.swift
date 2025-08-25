//
//  LegalView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct LegalView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Terms & Policies") {
                    NavigationLink(destination: TermsOfServiceView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Terms of Service")
                                Text("User agreement and service terms")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: PrivacyPolicyDetailView()) {
                        HStack {
                            Image(systemName: "lock.doc")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Privacy Policy")
                                Text("How we collect and use your data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: DataUsageDetailView()) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Data Usage Policy")
                                Text("How your swing data is processed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: CookiePolicyView()) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text("Cookie Policy")
                                Text("How we use cookies and tracking")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Intellectual Property") {
                    NavigationLink(destination: CopyrightView()) {
                        HStack {
                            Image(systemName: "c.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Copyright Notice")
                        }
                    }
                    
                    NavigationLink(destination: TrademarksView()) {
                        HStack {
                            Image(systemName: "tm.circle")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Trademarks")
                        }
                    }
                    
                    NavigationLink(destination: OpenSourceLicensesView()) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            Text("Open Source Licenses")
                        }
                    }
                }
                
                Section("Legal Information") {
                    NavigationLink(destination: DisclaimerView()) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Disclaimer")
                        }
                    }
                    
                    NavigationLink(destination: LimitationOfLiabilityView()) {
                        HStack {
                            Image(systemName: "shield")
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                            Text("Limitation of Liability")
                        }
                    }
                    
                    NavigationLink(destination: ComplianceView()) {
                        HStack {
                            Image(systemName: "checkmark.seal")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Compliance & Certifications")
                        }
                    }
                }
                
                Section("Contact") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Legal Questions")
                            .fontWeight(.medium)
                        
                        Button(action: { openEmail("legal@swingiq.com") }) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.blue)
                                Text("legal@swingiq.com")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Business Address")
                            .fontWeight(.medium)
                        
                        Text("SwingIQ Technologies Inc.\n123 Golf Drive\nPalo Alto, CA 94301\nUnited States")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Last Updated") {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Text("July 15, 2025")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Text("July 20, 2025")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Data Usage Policy")
                        Spacer()
                        Text("July 10, 2025")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Legal Document Views

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Effective Date: July 15, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    SectionHeader("1. Acceptance of Terms")
                    Text("By downloading, installing, or using SwingIQ, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.")
                    
                    SectionHeader("2. Description of Service")
                    Text("SwingIQ is a golf swing analysis application that uses computer vision technology to analyze golf swings captured through your device's camera. The service provides feedback on swing mechanics, tempo, and other golf-related metrics.")
                    
                    SectionHeader("3. User Account and Registration")
                    Text("• You may be required to create an account to access certain features\n• You are responsible for maintaining the confidentiality of your account\n• You must provide accurate and complete information\n• You are responsible for all activities under your account")
                    
                    SectionHeader("4. Acceptable Use")
                    Text("You agree to use SwingIQ only for lawful purposes and in accordance with these Terms. You may not:\n• Use the service for any illegal or unauthorized purpose\n• Interfere with or disrupt the service\n• Attempt to gain unauthorized access to our systems\n• Upload malicious code or content")
                    
                    SectionHeader("5. Intellectual Property")
                    Text("SwingIQ and its content are protected by copyright, trademark, and other intellectual property laws. You are granted a limited, non-exclusive license to use the application for personal, non-commercial purposes.")
                }
                
                Group {
                    SectionHeader("6. Privacy and Data")
                    Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.")
                    
                    SectionHeader("7. Subscription and Payment")
                    Text("• Some features require a paid subscription\n• Subscriptions automatically renew unless cancelled\n• Refunds are subject to Apple's App Store policies\n• Prices may change with 30 days notice")
                    
                    SectionHeader("8. Disclaimers")
                    Text("SwingIQ is provided 'as is' without warranties of any kind. We do not guarantee the accuracy of swing analysis or that the service will be uninterrupted or error-free.")
                    
                    SectionHeader("9. Limitation of Liability")
                    Text("In no event shall SwingIQ be liable for any indirect, incidental, special, or consequential damages resulting from your use of the service.")
                    
                    SectionHeader("10. Termination")
                    Text("We may terminate or suspend your account at any time for violation of these terms. You may cancel your account at any time through the app settings.")
                }
                
                Group {
                    SectionHeader("11. Changes to Terms")
                    Text("We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.")
                    
                    SectionHeader("12. Governing Law")
                    Text("These terms are governed by the laws of California, United States, without regard to conflict of law principles.")
                    
                    SectionHeader("13. Contact Information")
                    Text("For questions about these Terms, contact us at legal@swingiq.com")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: July 20, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    SectionHeader("Information We Collect")
                    Text("Personal Information:")
                    Text("• Name and email address (when you create an account)\n• Profile information (height, dominant hand, skill level)\n• Device information (model, iOS version)")
                    
                    Text("Swing Data:")
                    Text("• Video recordings of your golf swings\n• Swing analysis results and metrics\n• Usage data and app interactions")
                    
                    SectionHeader("How We Use Your Information")
                    Text("We use your information to:\n• Provide swing analysis and feedback\n• Improve our algorithms and services\n• Communicate with you about updates and features\n• Provide customer support")
                    
                    SectionHeader("Data Storage and Security")
                    Text("• Swing videos are stored locally on your device\n• Analysis data may be synced to iCloud if enabled\n• We use industry-standard encryption to protect your data\n• Personal information is stored on secure servers")
                }
                
                Group {
                    SectionHeader("Data Sharing")
                    Text("We do not sell your personal information. We may share data in these situations:\n• With your explicit consent (e.g., sharing with a coach)\n• Anonymized data for research and improvement\n• When required by law or legal process")
                    
                    SectionHeader("Your Rights")
                    Text("You have the right to:\n• Access your personal data\n• Correct inaccurate information\n• Delete your account and data\n• Export your data\n• Opt out of analytics")
                    
                    SectionHeader("Children's Privacy")
                    Text("SwingIQ is not intended for children under 13. We do not knowingly collect personal information from children under 13.")
                    
                    SectionHeader("International Users")
                    Text("If you're outside the United States, your data may be transferred to and processed in the US, where our servers are located.")
                    
                    SectionHeader("Changes to Privacy Policy")
                    Text("We may update this policy from time to time. We'll notify you of significant changes through the app or email.")
                }
                
                Group {
                    SectionHeader("Contact Us")
                    Text("For privacy questions or to exercise your rights, contact us at:\nprivacy@swingiq.com")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataUsageDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Usage Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: July 10, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    SectionHeader("Local Processing")
                    Text("SwingIQ performs swing analysis locally on your device using advanced computer vision algorithms. Your swing videos are processed without sending them to our servers, ensuring your privacy and data security.")
                    
                    SectionHeader("Cloud Services")
                    Text("Optional cloud features:\n• iCloud sync for analysis history\n• Profile backup and restore\n• Cross-device synchronization")
                    
                    SectionHeader("Analytics Data")
                    Text("With your consent, we collect anonymized usage data to improve SwingIQ:\n• App performance metrics\n• Feature usage statistics\n• Crash reports and error logs\n• General usage patterns")
                    
                    SectionHeader("Coach Sharing")
                    Text("When you connect with a coach:\n• You control what data is shared\n• Coaches can view shared swing analyses\n• You can revoke access at any time\n• All sharing requires your explicit consent")
                }
                
                Group {
                    SectionHeader("Data Retention")
                    Text("• Swing videos: Stored locally until you delete them\n• Analysis results: Retained until account deletion\n• Usage data: Anonymized and retained for 2 years\n• Account data: Deleted within 30 days of account closure")
                    
                    SectionHeader("Third-Party Services")
                    Text("SwingIQ integrates with:\n• Apple's Core ML for on-device analysis\n• iCloud for optional data sync\n• Apple's App Store for subscriptions")
                    
                    SectionHeader("Data Minimization")
                    Text("We follow data minimization principles:\n• Collect only necessary information\n• Process data locally when possible\n• Anonymize data for analytics\n• Regular data cleanup and archival")
                    
                    SectionHeader("Your Control")
                    Text("You can control your data through:\n• Privacy settings in the app\n• iCloud sync preferences\n• Coach sharing permissions\n• Data export and deletion options")
                }
            }
            .padding()
        }
        .navigationTitle("Data Usage Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CookiePolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cookie Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: July 20, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    SectionHeader("What Are Cookies")
                    Text("Cookies are small data files stored on your device when you use our app or visit our website. SwingIQ uses minimal tracking technologies to improve your experience.")
                    
                    SectionHeader("How We Use Cookies")
                    Text("• Authentication: Keep you signed in to your account\n• Preferences: Remember your app settings\n• Analytics: Understand how you use SwingIQ\n• Performance: Improve app loading and functionality")
                    
                    SectionHeader("Types of Cookies")
                    Text("Essential Cookies: Required for basic app functionality\nAnalytical Cookies: Help us understand usage patterns\nPreference Cookies: Remember your settings and choices")
                    
                    SectionHeader("Managing Cookies")
                    Text("You can control cookie preferences through:\n• iOS Settings > Privacy & Security\n• SwingIQ app privacy settings\n• Your browser settings (for our website)")
                }
            }
            .padding()
        }
        .navigationTitle("Cookie Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CopyrightView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Copyright Notice")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("© 2025 SwingIQ Technologies Inc. All rights reserved.")
                    .fontWeight(.medium)
                
                Group {
                    SectionHeader("Protected Content")
                    Text("The following are protected by copyright:\n• SwingIQ application and source code\n• User interface design and graphics\n• Analysis algorithms and methodologies\n• Documentation and help content\n• Marketing materials and branding")
                    
                    SectionHeader("Permitted Use")
                    Text("You may use SwingIQ for personal, non-commercial purposes in accordance with our Terms of Service. Commercial use requires written permission.")
                    
                    SectionHeader("Copyright Infringement")
                    Text("If you believe your copyrighted work has been used inappropriately, please contact us at legal@swingiq.com with:\n• Description of the copyrighted work\n• Location of the infringing material\n• Your contact information\n• Good faith statement of unauthorized use")
                }
            }
            .padding()
        }
        .navigationTitle("Copyright")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TrademarksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trademarks")
                    .font(.title)
                    .fontWeight(.bold)
                
                Group {
                    SectionHeader("SwingIQ Trademarks")
                    Text("The following are trademarks of SwingIQ Technologies Inc.:\n• SwingIQ™\n• SwingIQ logo and design marks\n• \"Swing Smart, Play Better\"™")
                    
                    SectionHeader("Third-Party Trademarks")
                    Text("• Apple, iPhone, iPad, iOS, and App Store are trademarks of Apple Inc.\n• Any other trademarks mentioned are the property of their respective owners")
                    
                    SectionHeader("Trademark Usage")
                    Text("Our trademarks may not be used without written permission except in limited circumstances such as fair use for commentary or review.")
                }
            }
            .padding()
        }
        .navigationTitle("Trademarks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OpenSourceLicensesView: View {
    var body: some View {
        List {
            Section("Core Dependencies") {
                LicenseRow(name: "Swift", license: "Apache 2.0", url: "https://swift.org/license")
                LicenseRow(name: "SwiftUI", license: "Apple EULA", url: nil)
                LicenseRow(name: "Core ML", license: "Apple EULA", url: nil)
            }
            
            Section("Third-Party Libraries") {
                LicenseRow(name: "Alamofire", license: "MIT", url: "https://github.com/Alamofire/Alamofire/blob/master/LICENSE")
                LicenseRow(name: "SwiftyJSON", license: "MIT", url: "https://github.com/SwiftyJSON/SwiftyJSON/blob/master/LICENSE")
            }
            
            Section("Attribution") {
                Text("SwingIQ makes use of open source software. We thank the open source community for their contributions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseRow: View {
    let name: String
    let license: String
    let url: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .fontWeight(.medium)
                Spacer()
                Text(license)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let url = url {
                Button("View License") {
                    if let licenseUrl = URL(string: url) {
                        UIApplication.shared.open(licenseUrl)
                    }
                }
                .font(.caption)
            }
        }
    }
}

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Disclaimer")
                    .font(.title)
                    .fontWeight(.bold)
                
                Group {
                    SectionHeader("General Disclaimer")
                    Text("SwingIQ is provided for informational and educational purposes only. The swing analysis and feedback provided by the app should not be considered professional golf instruction.")
                    
                    SectionHeader("Accuracy of Analysis")
                    Text("While SwingIQ uses advanced technology to analyze golf swings, the accuracy of results may vary based on video quality, lighting conditions, and other factors. Users should not rely solely on app analysis for golf improvement.")
                    
                    SectionHeader("Not Professional Advice")
                    Text("SwingIQ does not replace professional golf instruction. For personalized coaching and improvement, please consult with a qualified golf professional.")
                    
                    SectionHeader("Use at Your Own Risk")
                    Text("Use of SwingIQ is at your own risk. We are not responsible for any injury or damage that may result from following the app's recommendations or using the service.")
                }
            }
            .padding()
        }
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LimitationOfLiabilityView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Limitation of Liability")
                    .font(.title)
                    .fontWeight(.bold)
                
                Group {
                    SectionHeader("Liability Limitations")
                    Text("In no event shall SwingIQ Technologies Inc., its officers, directors, employees, or agents be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.")
                    
                    SectionHeader("Maximum Liability")
                    Text("Our total liability for any claims arising from or related to SwingIQ shall not exceed the amount you paid for the service in the 12 months preceding the claim.")
                    
                    SectionHeader("Service Availability")
                    Text("We do not guarantee that SwingIQ will be available at all times or that it will be free from errors, viruses, or other harmful components.")
                    
                    SectionHeader("Force Majeure")
                    Text("We shall not be liable for any failure or delay in performance due to circumstances beyond our reasonable control, including but not limited to acts of God, natural disasters, war, terrorism, or government actions.")
                }
            }
            .padding()
        }
        .navigationTitle("Limitation of Liability")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComplianceView: View {
    var body: some View {
        List {
            Section("Privacy Compliance") {
                ComplianceRow(standard: "GDPR", description: "General Data Protection Regulation", status: "Compliant")
                ComplianceRow(standard: "CCPA", description: "California Consumer Privacy Act", status: "Compliant")
                ComplianceRow(standard: "COPPA", description: "Children's Online Privacy Protection", status: "Compliant")
            }
            
            Section("Security Standards") {
                ComplianceRow(standard: "SOC 2", description: "Security and Availability", status: "In Progress")
                ComplianceRow(standard: "ISO 27001", description: "Information Security Management", status: "Planned")
            }
            
            Section("Platform Compliance") {
                ComplianceRow(standard: "App Store Guidelines", description: "Apple App Store Review Guidelines", status: "Compliant")
                ComplianceRow(standard: "iOS Privacy", description: "iOS Privacy Requirements", status: "Compliant")
            }
            
            Section("Accessibility") {
                ComplianceRow(standard: "WCAG 2.1", description: "Web Content Accessibility Guidelines", status: "In Progress")
                ComplianceRow(standard: "Section 508", description: "US Federal Accessibility Standards", status: "Planned")
            }
        }
        .navigationTitle("Compliance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComplianceRow: View {
    let standard: String
    let description: String
    let status: String
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "compliant": return .green
        case "in progress": return .orange
        case "planned": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(standard)
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

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
}

#Preview {
    LegalView()
}
