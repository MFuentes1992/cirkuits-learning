//
//  ComboGauge.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 29/10/25.
//

import SwiftUI

struct ComboGauge: View {
    let combo: Int
    let maxCombo: Int = 5
    @State private var animateLastBar = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main gauge container
            ZStack {
                // Background shape
                ParallelogramStack()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 120, height: 200)
                
                // Filled bars
                VStack(spacing: 8) {
                    ForEach(0..<maxCombo, id: \.self) { index in
                        let barNumber = maxCombo - index
                        ParallelogramBar()
                            .fill(combo >= barNumber ? Color(red: 0.78, green: 1.0, blue: 0) : Color.clear)
                            .frame(width: 100, height: 28)
                            .overlay(
                                ParallelogramBar()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: combo >= barNumber ? Color(red: 0.78, green: 1.0, blue: 0).opacity(0.6) : .clear, radius: 8)
                            .scaleEffect(animateLastBar && combo == barNumber ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: combo)
                    }
                }
                .padding(.top, 20)
            }
            
            // Combo multiplier badge
            ZStack {
                Circle()
                    .fill(Color(red: 0.96, green: 0.96, blue: 0.86))
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                
                Text("x\(String(format: "%02d", combo))")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.17, green: 0.09, blue: 0.06))
            }
            .offset(x: 30, y: 10)
            
            // "COMBO" text
            Text("COMBO")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                .offset(y: 30)
        }
    }
}
