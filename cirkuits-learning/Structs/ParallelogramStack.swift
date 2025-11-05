//
//  ParallelogramStack.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 29/10/25.
//
import SwiftUI
struct ParallelogramStack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let skew: CGFloat = 15
        
        path.move(to: CGPoint(x: skew, y: 0))
        path.addLine(to: CGPoint(x: rect.width - skew, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}
