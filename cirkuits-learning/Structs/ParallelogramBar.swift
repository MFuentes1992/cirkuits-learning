//
//  ParallelogramBar.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 29/10/25.
//
import SwiftUI
struct ParallelogramBar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let skew: CGFloat = 8
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}
