//
//  ClubSelectionView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct ClubSelectionView: View {
    @State private var defaultClub = "7 Iron"
    @State private var bagConfiguration = "Standard 14-Club Set"
    @State private var trackClubData = true
    @State private var autoDetectClub = false
    @State private var showClubSuggestions = true
    @State private var customClubs: [CustomClub] = []
    
    let defaultClubOptions = ["Driver", "3 Wood", "5 Wood", "3 Iron", "4 Iron", "5 Iron", "6 Iron", "7 Iron", "8 Iron", "9 Iron", "PW", "SW", "LW", "Putter"]
    let bagConfigurations = ["Standard 14-Club Set", "Custom Set", "Half Set", "Beginner Set", "Professional Set"]
    
    var body: some View {
        NavigationView {
            List {
                Section("Default Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default Practice Club")
                            Spacer()
                            Picker("Default Club", selection: $defaultClub) {
                                ForEach(defaultClubOptions, id: \.self) { club in
                                    Text(club).tag(club)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Club automatically selected when starting new analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bag Configuration")
                            Spacer()
                            Picker("Bag Type", selection: $bagConfiguration) {
                                ForEach(bagConfigurations, id: \.self) { config in
                                    Text(config).tag(config)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Your current golf bag setup")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Club Detection") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Auto-Detect Club", isOn: $autoDetectClub)
                        
                        Text("Automatically identify club type from swing characteristics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Track Club Data", isOn: $trackClubData)
                        
                        Text("Store and analyze performance data by club type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Club Suggestions", isOn: $showClubSuggestions)
                        
                        Text("Get recommendations for club selection based on distance and conditions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Your Clubs") {
                    NavigationLink("Manage Golf Bag") {
                        GolfBagManagementView()
                    }
                    
                    NavigationLink("Custom Club Setup") {
                        CustomClubSetupView()
                    }
                    
                    NavigationLink("Club Performance Stats") {
                        ClubPerformanceView()
                    }
                }
                
                Section("Presets") {
                    Button("Load Standard Set") {
                        loadStandardSet()
                    }
                    
                    Button("Load Beginner Set") {
                        loadBeginnerSet()
                    }
                    
                    Button("Load Professional Set") {
                        loadProfessionalSet()
                    }
                }
                
                if !customClubs.isEmpty {
                    Section("Custom Clubs") {
                        ForEach(customClubs) { club in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(club.name)
                                        .fontWeight(.medium)
                                    Text("\(club.loft)° • \(club.type)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Edit") {
                                    // Edit custom club
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .onDelete(perform: deleteCustomClub)
                    }
                }
            }
            .navigationTitle("Club Selection")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadClubSettings()
            }
            .onChange(of: defaultClub) { _ in saveClubSettings() }
            .onChange(of: bagConfiguration) { _ in saveClubSettings() }
            .onChange(of: trackClubData) { _ in saveClubSettings() }
            .onChange(of: autoDetectClub) { _ in saveClubSettings() }
            .onChange(of: showClubSuggestions) { _ in saveClubSettings() }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadClubSettings() {
        defaultClub = UserDefaults.standard.string(forKey: "defaultClub") ?? "7 Iron"
        bagConfiguration = UserDefaults.standard.string(forKey: "bagConfiguration") ?? "Standard 14-Club Set"
        trackClubData = UserDefaults.standard.object(forKey: "trackClubData") != nil ? UserDefaults.standard.bool(forKey: "trackClubData") : true
        autoDetectClub = UserDefaults.standard.bool(forKey: "autoDetectClub")
        showClubSuggestions = UserDefaults.standard.object(forKey: "showClubSuggestions") != nil ? UserDefaults.standard.bool(forKey: "showClubSuggestions") : true
        
        loadCustomClubs()
    }
    
    private func saveClubSettings() {
        UserDefaults.standard.set(defaultClub, forKey: "defaultClub")
        UserDefaults.standard.set(bagConfiguration, forKey: "bagConfiguration")
        UserDefaults.standard.set(trackClubData, forKey: "trackClubData")
        UserDefaults.standard.set(autoDetectClub, forKey: "autoDetectClub")
        UserDefaults.standard.set(showClubSuggestions, forKey: "showClubSuggestions")
    }
    
    private func loadCustomClubs() {
        // Load custom clubs from UserDefaults or Core Data
        customClubs = [
            CustomClub(name: "Custom Driver", type: "Driver", loft: 10.5, length: 45.5),
            CustomClub(name: "Hybrid 4", type: "Hybrid", loft: 22, length: 39.0)
        ]
    }
    
    private func deleteCustomClub(at offsets: IndexSet) {
        customClubs.remove(atOffsets: offsets)
    }
    
    private func loadStandardSet() {
        bagConfiguration = "Standard 14-Club Set"
        saveClubSettings()
    }
    
    private func loadBeginnerSet() {
        bagConfiguration = "Beginner Set"
        saveClubSettings()
    }
    
    private func loadProfessionalSet() {
        bagConfiguration = "Professional Set"
        saveClubSettings()
    }
}

// MARK: - Data Models

struct CustomClub: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let loft: Double
    let length: Double
}

// MARK: - Supporting Views

struct GolfBagManagementView: View {
    @State private var clubs: [BagClub] = []
    
    var body: some View {
        List {
            Section("Current Bag") {
                ForEach(clubs) { club in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(club.name)
                                .fontWeight(.medium)
                            HStack {
                                Text("\(club.loft, specifier: "%.1f")°")
                                Text("•")
                                Text(club.brand)
                                Text("•")
                                Text(club.model)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Stats") {
                            // Show club stats
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .onDelete(perform: deleteClub)
            }
            
            Section("Add Club") {
                Button("Add New Club") {
                    // Add new club to bag
                }
                
                NavigationLink("Scan Club QR Code") {
                    ClubScannerView()
                }
                
                NavigationLink("Import from Manufacturer") {
                    ManufacturerImportView()
                }
            }
        }
        .navigationTitle("Golf Bag")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBagClubs()
        }
    }
    
    private func loadBagClubs() {
        clubs = [
            BagClub(name: "Driver", brand: "TaylorMade", model: "SIM2", loft: 10.5),
            BagClub(name: "3 Wood", brand: "Callaway", model: "Epic Speed", loft: 15.0),
            BagClub(name: "5 Iron", brand: "Ping", model: "G425", loft: 27.0),
            BagClub(name: "7 Iron", brand: "Ping", model: "G425", loft: 34.0),
            BagClub(name: "9 Iron", brand: "Ping", model: "G425", loft: 42.0),
            BagClub(name: "Pitching Wedge", brand: "Ping", model: "G425", loft: 47.0),
            BagClub(name: "Sand Wedge", brand: "Vokey", model: "SM8", loft: 56.0),
            BagClub(name: "Putter", brand: "Odyssey", model: "White Hot", loft: 3.0)
        ]
    }
    
    private func deleteClub(at offsets: IndexSet) {
        clubs.remove(atOffsets: offsets)
    }
}

struct CustomClubSetupView: View {
    @State private var clubName = ""
    @State private var clubType = "Iron"
    @State private var loft = ""
    @State private var length = ""
    @State private var brand = ""
    @State private var model = ""
    
    let clubTypes = ["Driver", "Wood", "Hybrid", "Iron", "Wedge", "Putter"]
    
    var body: some View {
        Form {
            Section("Club Details") {
                TextField("Club Name", text: $clubName)
                
                Picker("Club Type", selection: $clubType) {
                    ForEach(clubTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                TextField("Loft (degrees)", text: $loft)
                    .keyboardType(.decimalPad)
                
                TextField("Length (inches)", text: $length)
                    .keyboardType(.decimalPad)
            }
            
            Section("Manufacturer") {
                TextField("Brand", text: $brand)
                TextField("Model", text: $model)
            }
            
            Section {
                Button("Save Club") {
                    saveCustomClub()
                }
                .disabled(clubName.isEmpty || loft.isEmpty)
            }
        }
        .navigationTitle("Custom Club")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveCustomClub() {
        // Save custom club to storage
    }
}

struct ClubPerformanceView: View {
    let performanceData = [
        ("Driver", "Average: 285 yards", "Best: 310 yards", "85% fairways"),
        ("7 Iron", "Average: 155 yards", "Best: 165 yards", "92% accuracy"),
        ("Pitching Wedge", "Average: 120 yards", "Best: 130 yards", "95% accuracy")
    ]
    
    var body: some View {
        List {
            Section("Performance Summary") {
                ForEach(performanceData, id: \.0) { data in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.0)
                            .fontWeight(.medium)
                        HStack {
                            Text(data.1)
                            Spacer()
                            Text(data.3)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        Text(data.2)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Section("Detailed Analysis") {
                NavigationLink("Distance Trends") {
                    DistanceTrendsView()
                }
                
                NavigationLink("Accuracy Analysis") {
                    AccuracyAnalysisView()
                }
                
                NavigationLink("Club Recommendations") {
                    ClubRecommendationsView()
                }
            }
        }
        .navigationTitle("Club Performance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClubScannerView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Scan Club QR Code")
                .font(.title2)
                .fontWeight(.medium)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 250, height: 250)
                .overlay(
                    Text("Camera View")
                        .foregroundColor(.secondary)
                )
            
            Text("Position QR code within the frame")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Manual Entry") {
                // Switch to manual club entry
            }
        }
        .padding()
        .navigationTitle("Scan Club")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ManufacturerImportView: View {
    let manufacturers = ["TaylorMade", "Callaway", "Ping", "Titleist", "Mizuno", "Cobra", "Wilson"]
    
    var body: some View {
        List {
            Section("Select Manufacturer") {
                ForEach(manufacturers, id: \.self) { manufacturer in
                    NavigationLink(manufacturer) {
                        ManufacturerClubsView(manufacturer: manufacturer)
                    }
                }
            }
        }
        .navigationTitle("Import Clubs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ManufacturerClubsView: View {
    let manufacturer: String
    
    var body: some View {
        List {
            Section("\(manufacturer) Clubs") {
                Text("Club import feature coming soon")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DistanceTrendsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Distance trends chart would be displayed here")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Distance Trends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccuracyAnalysisView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Accuracy analysis charts would be displayed here")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Accuracy Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClubRecommendationsView: View {
    var body: some View {
        List {
            Section("Recommendations") {
                Text("Based on your swing analysis, consider adjusting your 7-iron setup")
                Text("Your driver performance could improve with a lower loft")
                Text("Consider adding a gap wedge to your bag")
            }
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BagClub: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let model: String
    let loft: Double
}

#Preview {
    ClubSelectionView()
}
