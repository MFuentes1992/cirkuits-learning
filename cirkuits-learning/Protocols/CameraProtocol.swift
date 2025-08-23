//
//  CameraProtocol.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 22/08/25.
//
import simd

protocol CameraProtocol {
    var x: Float { get }
    var y: Float { get }
    var z: Float { get }
    var aspectRatio: Float { get }
    var fov: Float { get }
    var nearPlane: Float { get }
    var farPlane: Float { get }
    var screenLimits: SIMD2<Float> { get }
    
    var cameraSettings: CameraSettings { get }
    var viewMatrix: simd_float4x4 { get }
    var modelMatrix: simd_float4x4 { get }
    var projectionMatrix: simd_float4x4 { get }
    
    
    mutating func update(deltaTime: Float)
    mutating func lookAt(x: Float, y: Float, z: Float)
    mutating func move(forward: Bool, backward: Bool, left: Bool, right: Bool)
    mutating func strafe(left: Bool, right: Bool)
    mutating func fly(up: Bool, down: Bool)
    mutating func pitch(up: Bool, down: Bool)
    mutating func yaw(left: Bool, right: Bool)
    
}
