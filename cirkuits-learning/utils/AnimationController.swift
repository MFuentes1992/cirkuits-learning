//
//  AnimationController.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 31/08/25.
//

import Foundation
import simd

struct TimeUniforms {
    var time: Float
    var zoomAmount: Float
    var zoomSpeed: Float
}

class AnimationController {
    private var startTime: CFTimeInterval?
    private var uniforms = TimeUniforms(time: 0, zoomAmount: 0.5, zoomSpeed: 1.0)
    
    func updateUniforms(currentTime: CFTimeInterval) {
        if startTime == nil {
            startTime = currentTime
        }
        
        uniforms.time = Float(currentTime - startTime!)
    }
    
    func getUniforms() -> TimeUniforms {
        return uniforms
    }    
}
