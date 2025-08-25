//
//  ImageGolferFigurine.swift
//  SwingIQ
//
//  Golfer figurine using imported PNG image
//

import SwiftUI

struct ImageGolferFigurine: View {
    var body: some View {
        HStack {
            Spacer()
            
            // Try both possible image names with fallback
            Group {
                if let _ = UIImage(named: "golfer-figurine") {
                    Image("golfer-figurine")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.clear)
                        .colorMultiply(Color.white.opacity(0.95))
                } else if let _ = UIImage(named: "golfer-figurine 1") {
                    Image("golfer-figurine 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Fallback to SF Symbol
                    Image(systemName: "figure.golf")
                        .font(.system(size: 100))
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 406, height: 569)
            .offset(x: -40)
            
            Spacer()
        }
    }
}

#Preview {
    ImageGolferFigurine()
        .background(Color.white)
}
