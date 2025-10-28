//
//  WordLayoutConfig.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//

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
