//
//  PracticeStreakDashboard.swift
//  SwingIQ
//
//  Created by Amp on 7/22/25.
//

import SwiftUI
import Charts

struct PracticeStreakDashboard: View {
    let analyses: [SwingAnalysis]
    @State private var selectedMonth = Date()
    @State private var showingMonthPicker = false
    
    private var practiceData: [PracticeDay] {
        generatePracticeData(for: selectedMonth)
    }
    
    private var daysThisWeek: Int {
        calculateDaysThisWeek()
    }
    
    private var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    private var longestStreak: Int {
        calculateLongestStreak()
    }
    
    private var activeDaysThisMonth: Int {
        practiceData.filter { $0.isActive }.count
    }
    
    private var totalSessions: Int {
        practiceData.reduce(0) { $0 + $1.sessionCount }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with month selector
                headerSection
                
                // Streak metrics cards
                streakMetricsCards
                
                // Activity calendar
                activityCalendar
                
                // Weekly patterns
                weeklyPatterns
                
                // Goal tracking
                goalTracking
                
                // Insights
                practiceInsights
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Practice Streak")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Practice Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Month selector
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: { showingMonthPicker = true }) {
                    Text(monthYear(selectedMonth))
                        .font(.headline)
                        .foregroundColor(.black)
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
    
    // MARK: - Streak Metrics Cards
    
    private var streakMetricsCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            metricCard(
                title: "Days This Week", 
                value: "\(daysThisWeek)", 
                subtitle: daysThisWeek == 1 ? "day practiced" : "days practiced",
                color: .green,
                icon: "calendar.badge.checkmark"
            )
            metricCard(
                title: "Current Streak", 
                value: "\(currentStreak)", 
                subtitle: currentStreak == 1 ? "day" : "days",
                color: .orange,
                icon: "flame"
            )
            metricCard(
                title: "Active Days", 
                value: "\(activeDaysThisMonth)", 
                subtitle: "this month",
                color: .blue,
                icon: "calendar"
            )
            metricCard(
                title: "Total Sessions", 
                value: "\(totalSessions)", 
                subtitle: "this month",
                color: .purple,
                icon: "figure.golf"
            )
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Activity Calendar
    
    private var activityCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Calendar")
                .font(.headline)
                .foregroundColor(.primary)
            
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
                
                // Calendar grid
                let daysInMonth = getDaysInMonth(selectedMonth)
                let firstWeekday = getFirstWeekdayOfMonth(selectedMonth)
                let totalCells = daysInMonth + firstWeekday - 1
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(0..<totalCells, id: \.self) { index in
                        if index < firstWeekday - 1 {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 40)
                        } else {
                            let dayIndex = index - (firstWeekday - 1)
                            let practiceDay = practiceData[safe: dayIndex] ?? PracticeDay(day: dayIndex + 1, sessionCount: 0)
                            
                            calendarDay(practiceDay: practiceDay)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func calendarDay(practiceDay: PracticeDay) -> some View {
        VStack(spacing: 4) {
            Text("\(practiceDay.day)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(practiceDay.isActive ? .white : .primary)
            
            Circle()
                .fill(practiceIntensityColor(practiceDay.sessionCount))
                .frame(width: 8, height: 8)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(practiceDay.isToday ? Color.yellow.opacity(0.3) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(practiceDay.isToday ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Weekly Patterns
    
    private var weeklyPatterns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Patterns")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                let weeklyData = calculateWeeklyData()
                
                Chart {
                    ForEach(weeklyData, id: \.day) { data in
                        BarMark(
                            x: .value("Day", data.day),
                            y: .value("Sessions", data.sessions)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 150)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                Text("Weekly patterns chart requires iOS 16+")
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Goal Tracking
    
    private var goalTracking: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Goals")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                goalProgress(
                    title: "Practice Days",
                    current: activeDaysThisMonth,
                    target: 20,
                    color: .green
                )
                
                goalProgress(
                    title: "Total Sessions",
                    current: totalSessions,
                    target: 30,
                    color: .blue
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func goalProgress(title: String, current: Int, target: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                Rectangle()
                    .fill(color)
                    .frame(width: CGFloat(min(current, target)) / CGFloat(target) * UIScreen.main.bounds.width * 0.7, height: 8)
            }
            .cornerRadius(4)
        }
    }
    
    // MARK: - Practice Insights
    
    private var practiceInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "chart.bar",
                    title: "Best Practice Day",
                    description: getBestPracticeDay(),
                    color: .blue
                )
                
                insightCard(
                    icon: "target",
                    title: "Consistency",
                    description: getConsistencyInsight(),
                    color: .green
                )
                
                insightCard(
                    icon: "lightbulb",
                    title: "Recommendation",
                    description: getRecommendation(),
                    color: .orange
                )
            }
        }
    }
    
    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func calculateDaysThisWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of this week (Sunday)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return 0 }
        let startOfWeek = weekInterval.start
        let endOfWeek = weekInterval.end
        
        // Count unique days with analyses this week
        let thisWeekAnalyses = analyses.filter { analysis in
            analysis.timestamp >= startOfWeek && analysis.timestamp < endOfWeek
        }
        
        // Group by day and count unique days
        let uniqueDays = Set(thisWeekAnalyses.map { analysis in
            calendar.startOfDay(for: analysis.timestamp)
        })
        
        return uniqueDays.count
    }
    
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
    
    private func generatePracticeData(for month: Date) -> [PracticeDay] {
        let daysInMonth = getDaysInMonth(month)
        let calendar = Calendar.current
        let today = Date()
        
        return (1...daysInMonth).map { day in
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = day
            guard let date = calendar.date(from: components) else {
                return PracticeDay(day: day, sessionCount: 0)
            }
            
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isFuture = date > today
            
            // Use actual analysis data
            let sessionCount: Int
            if isFuture {
                sessionCount = 0
            } else {
                // Count analyses for this specific date
                let dayAnalyses = analyses.filter { analysis in
                    calendar.isDate(analysis.timestamp, inSameDayAs: date)
                }
                sessionCount = dayAnalyses.count
            }
            
            return PracticeDay(day: day, sessionCount: sessionCount, isToday: isToday)
        }
    }
    
    private func practiceIntensityColor(_ sessionCount: Int) -> Color {
        switch sessionCount {
        case 0:
            return Color(hex: "f1f3f4")
        case 1:
            return Color(hex: "c6e48b")
        case 2:
            return Color(hex: "7bc96f")
        case 3:
            return Color(hex: "239a3b")
        default:
            return Color(hex: "0d4429")
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        
        for i in 0..<30 {
            guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            
            // Check if there are any analyses for this date
            let hasAnalysisOnDate = analyses.contains { analysis in
                calendar.isDate(analysis.timestamp, inSameDayAs: checkDate)
            }
            
            if hasAnalysisOnDate {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        var maxStreak = 0
        var currentStreak = 0
        
        for practiceDay in practiceData {
            if practiceDay.isActive {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    private func calculateWeeklyData() -> [WeeklyData] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        return (1...7).map { dayOfWeek in
            let sessionsForDay = practiceData.compactMap { practiceDay -> Int? in
                var components = calendar.dateComponents([.year, .month], from: selectedMonth)
                components.day = practiceDay.day
                guard let date = calendar.date(from: components) else { return nil }
                
                return calendar.component(.weekday, from: date) == dayOfWeek ? practiceDay.sessionCount : nil
            }
            
            let totalSessions = sessionsForDay.reduce(0, +)
            return WeeklyData(day: dayNames[dayOfWeek - 1], sessions: totalSessions)
        }
    }
    
    private func getBestPracticeDay() -> String {
        let weeklyData = calculateWeeklyData()
        let bestDay = weeklyData.max(by: { $0.sessions < $1.sessions })
        return bestDay?.day ?? "No data"
    }
    
    private func getConsistencyInsight() -> String {
        let activeDaysPercentage = Double(activeDaysThisMonth) / Double(getDaysInMonth(selectedMonth)) * 100
        
        if activeDaysPercentage >= 70 {
            return "Excellent consistency this month"
        } else if activeDaysPercentage >= 50 {
            return "Good practice consistency"
        } else {
            return "Try to practice more regularly"
        }
    }
    
    private func getRecommendation() -> String {
        if currentStreak == 0 {
            return "Start a new practice streak today!"
        } else if currentStreak < 3 {
            return "Keep building your streak!"
        } else if currentStreak < 7 {
            return "Great momentum! Aim for a week-long streak"
        } else {
            return "Amazing streak! Keep up the excellent work"
        }
    }
}

// MARK: - Supporting Models

struct PracticeDay {
    let day: Int
    let sessionCount: Int
    let isToday: Bool
    
    init(day: Int, sessionCount: Int, isToday: Bool = false) {
        self.day = day
        self.sessionCount = sessionCount
        self.isToday = isToday
    }
    
    var isActive: Bool {
        sessionCount > 0
    }
}

struct WeeklyData {
    let day: String
    let sessions: Int
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationView {
        PracticeStreakDashboard(analyses: [])
    }
}
