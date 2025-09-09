//
//  DesignTokens.swift
//  SwingIQ
//
//  Created by Amp on 9/8/25.
//  Tailwind-inspired design system for consistent UI
//

import SwiftUI

// MARK: - Spacing Scale (Tailwind-inspired)

enum Spacing: CGFloat, CaseIterable {
    case xs = 4      // Tailwind 1
    case sm = 8      // Tailwind 2  
    case md = 16     // Tailwind 4
    case lg = 24     // Tailwind 6
    case xl = 32     // Tailwind 8
    case xxl = 48    // Tailwind 12
    case xxxl = 64   // Tailwind 16
}

// MARK: - Semantic Color System

extension Color {
    // Brand Colors
    static let iqBackground   = Color(.systemBackground)
    static let iqSurface      = Color.white
    static let iqPrimary      = Color(hex: "#166534")      // Dark golf green
    static let iqPrimaryLight = Color(hex: "#22c55e")      // Bright accent green
    static let iqSecondary    = Color(hex: "#64748b")      // Slate gray
    
    // Status Colors
    static let iqSuccess      = Color(hex: "#10b981")      // Emerald
    static let iqWarning      = Color(hex: "#f59e0b")      // Amber
    static let iqDanger       = Color(hex: "#dc2626")      // Red
    static let iqInfo         = Color(hex: "#3b82f6")      // Blue
    
    // Surface Colors
    static let iqMuted        = Color(.systemGray5)        // Light background
    static let iqBorder       = Color(.systemGray4)        // Borders
    static let iqDivider      = Color(.systemGray6)        // Subtle dividers
    
    // Text Colors
    static let iqTextPrimary  = Color(.label)              // High contrast
    static let iqTextSecondary = Color(.secondaryLabel)    // Medium contrast
    static let iqTextTertiary = Color(.tertiaryLabel)      // Low contrast
    
    // Using existing hex extension from ColorExtensions.swift
}

// MARK: - Typography Scale

extension Font {
    // Tailwind-inspired text sizes
    static let textXs  = Font.system(size: 11, weight: .regular)    // Small labels
    static let textSm  = Font.system(size: 13, weight: .regular)    // Secondary text
    static let textBase = Font.system(size: 15, weight: .medium)    // Body text
    static let textLg  = Font.system(size: 17, weight: .medium)     // Emphasis
    static let textXl  = Font.system(size: 20, weight: .semibold)   // Section headers
    static let text2Xl = Font.system(size: 24, weight: .bold)       // Page titles
    static let text3Xl = Font.system(size: 30, weight: .bold)       // Hero text
}

// MARK: - Elevation & Shadow System

struct Elevation {
    static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    static let md = (color: Color.black.opacity(0.08), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    static let lg = (color: Color.black.opacity(0.10), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    static let xl = (color: Color.black.opacity(0.12), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
}

// MARK: - Corner Radius System

enum CornerRadius: CGFloat {
    case sm = 6
    case md = 8
    case lg = 12
    case xl = 16
    case xxl = 24
}

// MARK: - Interaction States

struct InteractionState {
    static let pressScale: CGFloat = 0.97
    static let pressOpacity: Double = 0.85
    static let springResponse: Double = 0.25
    static let springDamping: Double = 0.8
}
