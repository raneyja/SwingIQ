//
//  SFSymbolGolferFigurine.swift
//  SwingIQ
//
//  Clean golfer figurine using SF Symbols
//

import SwiftUI

struct SFSymbolGolferFigurine: View {
    var body: some View {
        VStack(spacing: 8) {
            // Try different golf-related SF Symbols
            Image(systemName: "figure.golf")
                .font(.system(size: 120, weight: .regular))
                .foregroundColor(.primary)
        }
        .frame(width: 200, height: 280)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("SF Symbol Golfer")
        SFSymbolGolferFigurine()
            .background(Color.white)
    }
    .frame(width: 400, height: 500)
}
