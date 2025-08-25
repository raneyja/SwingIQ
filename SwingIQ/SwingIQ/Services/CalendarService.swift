//
//  CalendarService.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation
import EventKit

struct TeeTime {
    let id: String
    let courseName: String
    let date: Date
    let location: String?
    let notes: String?
    let originalEvent: EKEvent
}

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var upcomingTeeTimes: [TeeTime] = []
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestAccess(to: .event)
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .authorized
    }
    
    func fetchUpcomingEvents() async -> [EKEvent] {
        guard isAuthorized else {
            print("Calendar access not authorized")
            return []
        }
        
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: now) ?? now
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: futureDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        return events
    }
    
    func identifyTeeTimeEvents(from events: [EKEvent]) async -> [TeeTime] {
        var teeTimes: [TeeTime] = []
        
        for event in events {
            if await couldBeTeeTime(event) {
                let teeTime = TeeTime(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    courseName: extractCourseName(from: event),
                    date: event.startDate,
                    location: event.location,
                    notes: event.notes,
                    originalEvent: event
                )
                teeTimes.append(teeTime)
            }
        }
        
        return teeTimes.sorted { $0.date < $1.date }
    }
    
    private func couldBeTeeTime(_ event: EKEvent) async -> Bool {
        let title = event.title?.lowercased() ?? ""
        let location = event.location?.lowercased() ?? ""
        let notes = event.notes?.lowercased() ?? ""
        
        let golfKeywords = [
            "golf", "tee time", "tee", "course", "links", "country club",
            "golf club", "driving range", "putting", "golf lesson",
            "tournament", "scramble", "outing"
        ]
        
        let combinedText = "\(title) \(location) \(notes)"
        
        return golfKeywords.contains { keyword in
            combinedText.contains(keyword)
        }
    }
    
    private func extractCourseName(from event: EKEvent) -> String {
        if let location = event.location, !location.isEmpty {
            return location
        }
        
        if let title = event.title, !title.isEmpty {
            return title
        }
        
        return "Golf Course"
    }
    
    func refreshTeeTimes() async {
        guard await requestCalendarAccess() else { return }
        
        let events = await fetchUpcomingEvents()
        let teeTimes = await identifyTeeTimeEvents(from: events)
        
        await MainActor.run {
            self.upcomingTeeTimes = teeTimes
        }
    }
    
    func getNextTeeTime() -> TeeTime? {
        let now = Date()
        return upcomingTeeTimes.first { $0.date > now }
    }
}
