//
//  WordLayoutConfig.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//
import SwiftUI

struct WordLayoutConfig {
    let screenWidth: Float
    let maxLinearWidth: Float
    let letterWidth: Float
    let letterSpacing: Float
    let speed: Float
    let blankSpaceWidth: Float
    let startingPoint: Float = 0.0
    
    init(screenWidth: Float,
         maxWidthPercentage: Float = 0.6,
         letterSpacing: Float = 2.5,
         letterWidth: Float = 15,
         speed: Float = 1.5,
         blankSpaceWidth: Float = 10) {
        self.screenWidth = screenWidth
        self.maxLinearWidth = screenWidth * maxWidthPercentage
        self.letterSpacing = letterSpacing
        self.speed = speed
        self.blankSpaceWidth = blankSpaceWidth
        self.letterWidth = letterWidth
    }
}

struct UILayoutLookAndFeel {
    let color: UIColor
    let foreColor: UIColor
    let buttonSize: CGFloat
    let fontSize: CGFloat
    
    init(color: UIColor,
         foreColor: UIColor,
         buttonSize: CGFloat,
         fontSize: CGFloat) {
        self.color = color
        self.foreColor = foreColor
        self.buttonSize = buttonSize
        self.fontSize = fontSize
    }
}
