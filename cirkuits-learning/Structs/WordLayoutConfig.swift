//
//  WordLayoutConfig.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//

struct WordLayoutConfig {
    let screenWidth: Float
    let maxLinearWidth: Float
    let letterSpacing: Float
    let circleRadiusMultiplier: Float
    let rotationSpeed: Float
    let blankSpaceWidth: Float
    let circumferenceRadBounds: Float
    
    init(screenWidth: Float,
         maxWidthPercentage: Float = 0.8,
         letterSpacing: Float = 2.5,
         circleRadiusMultiplier: Float = 1,
         rotationSpeed: Float = 0.3,
         blankSpaceWidth: Float = 10) {
        self.screenWidth = screenWidth
        self.maxLinearWidth = screenWidth * maxWidthPercentage
        self.letterSpacing = letterSpacing
        self.circleRadiusMultiplier = circleRadiusMultiplier
        self.rotationSpeed = rotationSpeed
        self.blankSpaceWidth = blankSpaceWidth
        self.circumferenceRadBounds = .pi * 0.25 // -- Camera is facing at 0deg - bounds are at -30deg and 30deg
    }
}
