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
    
    init(screenWidth: Float,
         maxWidthPercentage: Float = 0.8,
         letterSpacing: Float = 2.5,
         circleRadiusMultiplier: Float = 1.5,
         rotationSpeed: Float = 0.5,
         blankSpaceWidth: Float = 10) {
        self.screenWidth = screenWidth
        self.maxLinearWidth = screenWidth * maxWidthPercentage
        self.letterSpacing = letterSpacing
        self.circleRadiusMultiplier = circleRadiusMultiplier
        self.rotationSpeed = rotationSpeed
        self.blankSpaceWidth = blankSpaceWidth
    }
}
