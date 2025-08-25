//
//  DetailedActivityCalendarView.swift
//  SwingIQ
//
//  Created by Amp on 7/20/25.
//

import SwiftUI

struct DetailedActivityCalendarView: View {
    @State private var selectedMonth = Date()
    @State private var showingMonthPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Month selector
            monthSelector
            
            // Calendar grid
            calendarGrid
            
            // Legend
            legend
            
            // Stats summary
            monthlyStats
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button(action: { changeMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: { showingMonthPicker = true }) {
                Text(monthYear(selectedMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: { changeMonth(1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showingMonthPicker) {
            monthPickerView
        }
    }
    
    private var monthPickerView: some View {
        NavigationView {
            DatePicker(
                "Select Month",
                selection: $selectedMonth,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingMonthPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            let daysInMonth = getDaysInMonth(selectedMonth)
            let firstWeekday = getFirstWeekdayOfMonth(selectedMonth)
            let totalCells = daysInMonth + firstWeekday - 1
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<totalCells, id: \.self) { index in
                    if index < firstWeekday - 1 {
                        // Empty cell for days before month starts
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                    } else {
                        let dayIndex = index - (firstWeekday - 1)
                        let intensity = getIntensity(for: dayIndex, in: selectedMonth)
                        let isToday = isToday(dayIndex, in: selectedMonth)
                        
                        calendarSquare(
                            day: dayIndex + 1,
                            intensity: intensity,
                            isToday: isToday
                        )
                    }
                }
            }
        }
    }
    
    private func calendarSquare(day: Int, intensity: Double, isToday: Bool) -> some View {
        VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(intensity > 0 ? .white : .primary)
            
            Rectangle()
                .fill(calendarColor(intensity: intensity))
                .frame(width: 20, height: 4)
                .cornerRadius(2)
        }
        .frame(width: 24, height: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isToday ? Color.yellow : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.15), value: intensity)
    }
    
    // MARK: - Legend
    private var legend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Activity Legend")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                legendItem(color: Color(hex: "f1f3f4"), text: "No activity")
                legendItem(color: Color(hex: "c6e48b"), text: "Light")
                legendItem(color: Color(hex: "7bc96f"), text: "Moderate")
                legendItem(color: Color(hex: "239a3b"), text: "Heavy")
                legendItem(color: Color(hex: "0d4429"), text: "Intense")
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Monthly Stats
    private var monthlyStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                statItem(title: "Total Sessions", value: "\(getTotalSessions())")
                statItem(title: "Active Days", value: "\(getActiveDays())")
                statItem(title: "Current Streak", value: "\(getCurrentStreak()) days")
                statItem(title: "Best Streak", value: "\(getBestStreak()) days")
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func changeMonth(_ direction: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
    
    private func monthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func getDaysInMonth(_ date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
    }
    
    private func getFirstWeekdayOfMonth(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDayOfMonth = calendar.date(from: components) ?? date
        return calendar.component(.weekday, from: firstDayOfMonth)
    }
    
    private func getIntensity(for day: Int, in month: Date) -> Double {
        // Generate realistic training data for the month
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        var dayComponents = components
        dayComponents.day = day + 1
        
        guard let date = calendar.date(from: dayComponents) else { return 0.0 }
        
        // Don't show intensity for future dates
        if date > Date() { return 0.0 }
        
        // Generate some realistic training patterns
        let dayOfWeek = calendar.component(.weekday, from: date)
        let isWeekend = dayOfWeek == 1 || dayOfWeek == 7
        
        // Higher chance of training on weekends
        let baseChance = isWeekend ? 0.7 : 0.4
        let random = Double.random(in: 0...1)
        
        if random < baseChance {
            return Double.random(in: 0.1...1.0)
        } else {
            return 0.0
        }
    }
    
    private func isToday(_ day: Int, in month: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: month)
        var dayComponents = components
        dayComponents.day = day + 1
        
        guard let date = calendar.date(from: dayComponents) else { return false }
        return calendar.isDate(date, inSameDayAs: today)
    }
    
    private func calendarColor(intensity: Double) -> Color {
        switch intensity {
        case 0.0:
            return Color(hex: "f1f3f4")
        case 0.01...0.2:
            return Color(hex: "c6e48b")
        case 0.21...0.4:
            return Color(hex: "7bc96f")
        case 0.41...0.6:
            return Color(hex: "239a3b")
        case 0.61...0.8:
            return Color(hex: "196127")
        default:
            return Color(hex: "0d4429")
        }
    }
    
    // MARK: - Stats Calculations
    private func getTotalSessions() -> Int {
        let daysInMonth = getDaysInMonth(selectedMonth)
        var sessions = 0
        
        for day in 0..<daysInMonth {
            let intensity = getIntensity(for: day, in: selectedMonth)
            if intensity > 0 {
                // Convert intensity to estimated sessions (1-3 sessions per active day)
                sessions += Int(intensity * 3) + 1
            }
        }
        
        return sessions
    }
    
    private func getActiveDays() -> Int {
        let daysInMonth = getDaysInMonth(selectedMonth)
        var activeDays = 0
        
        for day in 0..<daysInMonth {
            let intensity = getIntensity(for: day, in: selectedMonth)
            if intensity > 0 {
                activeDays += 1
            }
        }
        
        return activeDays
    }
    
    private func getCurrentStreak() -> Int {
        // Calculate current consecutive days of activity
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var checkDate = today
        
        // Go backwards from today to find consecutive active days
        for _ in 0..<30 { // Check up to 30 days back
            let dayOfMonth = calendar.component(.day, from: checkDate)
            let monthComponents = calendar.dateComponents([.year, .month], from: checkDate)
            
            if calendar.dateComponents([.year, .month], from: selectedMonth) == monthComponents {
                let intensity = getIntensity(for: dayOfMonth - 1, in: selectedMonth)
                if intensity > 0 {
                    streak += 1
                } else {
                    break
                }
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }
    
    private func getBestStreak() -> Int {
        // Calculate the longest consecutive streak in the month
        let daysInMonth = getDaysInMonth(selectedMonth)
        var maxStreak = 0
        var currentStreak = 0
        
        for day in 0..<daysInMonth {
            let intensity = getIntensity(for: day, in: selectedMonth)
            if intensity > 0 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
}

#Preview {
    DetailedActivityCalendarView()
}
