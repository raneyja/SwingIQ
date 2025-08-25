//
//  MeasurementUnitsView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct MeasurementUnitsView: View {
    @State private var swingSpeedUnit = "mph"
    @State private var distanceUnit = "yards"
    @State private var temperatureUnit = "°F"
    @State private var heightUnit = "feet"
    @State private var windSpeedUnit = "mph"
    @State private var angleUnit = "degrees"
    @State private var showDecimals = true
    @State private var roundValues = false
    @State private var showMetricFirst = false
    
    let speedOptions = ["mph", "km/h", "m/s"]
    let distanceOptions = ["yards", "meters", "feet"]
    let temperatureOptions = ["°F", "°C"]
    let heightOptions = ["feet", "meters"]
    let windOptions = ["mph", "km/h", "m/s", "knots"]
    let angleOptions = ["degrees", "radians"]
    
    var body: some View {
        NavigationView {
            List {
                Section("Swing Measurements") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Swing Speed")
                            Spacer()
                            Picker("Speed Unit", selection: $swingSpeedUnit) {
                                ForEach(speedOptions, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Units for club head speed and ball velocity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Club Angles")
                            Spacer()
                            Picker("Angle Unit", selection: $angleUnit) {
                                ForEach(angleOptions, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Units for club face angle, path, and swing plane")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Distance Measurements") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Distance")
                            Spacer()
                            Picker("Distance Unit", selection: $distanceUnit) {
                                ForEach(distanceOptions, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Units for carry distance, total distance, and shot dispersion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Height/Elevation")
                            Spacer()
                            Picker("Height Unit", selection: $heightUnit) {
                                ForEach(heightOptions, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Units for ball height, elevation changes, and player height")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Environmental") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Picker("Temperature Unit", selection: $temperatureUnit) {
                                ForEach(temperatureOptions, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Temperature units for weather conditions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Wind Speed")
                            Spacer()
                            Picker("Wind Unit", selection: $windSpeedUnit) {
                                ForEach(windOptions, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Wind speed units for course conditions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Display Options") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Decimal Places", isOn: $showDecimals)
                        
                        Text("Display measurements with decimal precision")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Round Values", isOn: $roundValues)
                        
                        Text("Round measurements to nearest whole number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Both Units", isOn: $showMetricFirst)
                        
                        Text("Display both metric and imperial units in analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Quick Convert") {
                    NavigationLink("Unit Converter") {
                        UnitConverterView()
                    }
                    
                    NavigationLink("Distance Chart") {
                        DistanceChartView()
                    }
                }
                
                Section("Regional Presets") {
                    Button("US/Imperial Units") {
                        setUSUnits()
                    }
                    
                    Button("Metric Units") {
                        setMetricUnits()
                    }
                    
                    Button("UK Units") {
                        setUKUnits()
                    }
                }
            }
            .navigationTitle("Measurement Units")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadMeasurementSettings()
            }
            .onChange(of: swingSpeedUnit) { _ in saveMeasurementSettings() }
            .onChange(of: distanceUnit) { _ in saveMeasurementSettings() }
            .onChange(of: temperatureUnit) { _ in saveMeasurementSettings() }
            .onChange(of: heightUnit) { _ in saveMeasurementSettings() }
            .onChange(of: windSpeedUnit) { _ in saveMeasurementSettings() }
            .onChange(of: angleUnit) { _ in saveMeasurementSettings() }
            .onChange(of: showDecimals) { _ in saveMeasurementSettings() }
            .onChange(of: roundValues) { _ in saveMeasurementSettings() }
            .onChange(of: showMetricFirst) { _ in saveMeasurementSettings() }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadMeasurementSettings() {
        swingSpeedUnit = UserDefaults.standard.string(forKey: "swingSpeedUnit") ?? "mph"
        distanceUnit = UserDefaults.standard.string(forKey: "distanceUnit") ?? "yards"
        temperatureUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "°F"
        heightUnit = UserDefaults.standard.string(forKey: "heightUnit") ?? "feet"
        windSpeedUnit = UserDefaults.standard.string(forKey: "windSpeedUnit") ?? "mph"
        angleUnit = UserDefaults.standard.string(forKey: "angleUnit") ?? "degrees"
        showDecimals = UserDefaults.standard.object(forKey: "showDecimals") != nil ? UserDefaults.standard.bool(forKey: "showDecimals") : true
        roundValues = UserDefaults.standard.bool(forKey: "roundValues")
        showMetricFirst = UserDefaults.standard.bool(forKey: "showMetricFirst")
    }
    
    private func saveMeasurementSettings() {
        UserDefaults.standard.set(swingSpeedUnit, forKey: "swingSpeedUnit")
        UserDefaults.standard.set(distanceUnit, forKey: "distanceUnit")
        UserDefaults.standard.set(temperatureUnit, forKey: "temperatureUnit")
        UserDefaults.standard.set(heightUnit, forKey: "heightUnit")
        UserDefaults.standard.set(windSpeedUnit, forKey: "windSpeedUnit")
        UserDefaults.standard.set(angleUnit, forKey: "angleUnit")
        UserDefaults.standard.set(showDecimals, forKey: "showDecimals")
        UserDefaults.standard.set(roundValues, forKey: "roundValues")
        UserDefaults.standard.set(showMetricFirst, forKey: "showMetricFirst")
    }
    
    private func setUSUnits() {
        swingSpeedUnit = "mph"
        distanceUnit = "yards"
        temperatureUnit = "°F"
        heightUnit = "feet"
        windSpeedUnit = "mph"
        angleUnit = "degrees"
        saveMeasurementSettings()
    }
    
    private func setMetricUnits() {
        swingSpeedUnit = "km/h"
        distanceUnit = "meters"
        temperatureUnit = "°C"
        heightUnit = "meters"
        windSpeedUnit = "km/h"
        angleUnit = "degrees"
        saveMeasurementSettings()
    }
    
    private func setUKUnits() {
        swingSpeedUnit = "mph"
        distanceUnit = "yards"
        temperatureUnit = "°C"
        heightUnit = "feet"
        windSpeedUnit = "mph"
        angleUnit = "degrees"
        saveMeasurementSettings()
    }
}

// MARK: - Supporting Views

struct UnitConverterView: View {
    @State private var inputValue = ""
    @State private var fromUnit = "mph"
    @State private var toUnit = "km/h"
    @State private var convertedValue = ""
    
    let speedUnits = ["mph", "km/h", "m/s"]
    let distanceUnits = ["yards", "meters", "feet"]
    let allUnits = ["mph", "km/h", "m/s", "yards", "meters", "feet", "°F", "°C"]
    
    var body: some View {
        List {
            Section("Convert") {
                HStack {
                    Text("From")
                    TextField("Value", text: $inputValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("From Unit", selection: $fromUnit) {
                        ForEach(allUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("To")
                    Text(convertedValue)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("To Unit", selection: $toUnit) {
                        ForEach(allUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Section("Common Conversions") {
                HStack {
                    Text("100 mph")
                    Spacer()
                    Text("160.9 km/h")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("300 yards")
                    Spacer()
                    Text("274.3 meters")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("70°F")
                    Spacer()
                    Text("21.1°C")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Unit Converter")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: inputValue) { _ in convertValue() }
        .onChange(of: fromUnit) { _ in convertValue() }
        .onChange(of: toUnit) { _ in convertValue() }
    }
    
    private func convertValue() {
        guard let value = Double(inputValue) else {
            convertedValue = ""
            return
        }
        
        // Simple conversion logic (would be more comprehensive in real app)
        if fromUnit == "mph" && toUnit == "km/h" {
            convertedValue = String(format: "%.1f", value * 1.609)
        } else if fromUnit == "km/h" && toUnit == "mph" {
            convertedValue = String(format: "%.1f", value / 1.609)
        } else if fromUnit == "yards" && toUnit == "meters" {
            convertedValue = String(format: "%.1f", value * 0.9144)
        } else if fromUnit == "meters" && toUnit == "yards" {
            convertedValue = String(format: "%.1f", value / 0.9144)
        } else {
            convertedValue = inputValue
        }
    }
}

struct DistanceChartView: View {
    let clubs = [
        ("Driver", "250-300 yards", "230-275 meters"),
        ("3 Wood", "220-250 yards", "200-230 meters"),
        ("5 Wood", "200-230 yards", "180-210 meters"),
        ("3 Iron", "180-210 yards", "165-195 meters"),
        ("5 Iron", "160-190 yards", "145-175 meters"),
        ("7 Iron", "140-170 yards", "130-155 meters"),
        ("9 Iron", "120-150 yards", "110-140 meters"),
        ("PW", "100-130 yards", "90-120 meters"),
        ("SW", "80-110 yards", "75-100 meters")
    ]
    
    var body: some View {
        List {
            Section("Average Distances") {
                ForEach(clubs, id: \.0) { club in
                    HStack {
                        Text(club.0)
                            .fontWeight(.medium)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(club.1)
                                .font(.caption)
                            Text(club.2)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Text("Distances are approximate and vary based on player skill, swing speed, and conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Distance Chart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MeasurementUnitsView()
}
