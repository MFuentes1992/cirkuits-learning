//
//  PerspectiveCamera.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 21/08/25.
//
import simd
struct CameraSettings {        
    var eye: SIMD3<Float>
    var center: SIMD3<Float>
    var up: SIMD3<Float>
    
    var fovDegrees: Float
    var aspectRatio: Float
    var nearZ: Float
    var farZ: Float
    
}
