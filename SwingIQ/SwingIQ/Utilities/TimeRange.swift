//
//  TimeRange.swift
//  SwingIQ
//
//  Created by SwingIQ on 1/26/25.
//

import Foundation

/// Shared TimeRange enum for filtering data across dashboard views
enum TimeRange: String, CaseIterable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case allTime = "All"
    
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return 365 * 10 // Large number for all time
        }
    }
}
