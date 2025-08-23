//
//  Camera.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 22/08/25.
//
import simd

class Camera: CameraProtocol {
    
    var settings: CameraSettings!
    
    init (settings: CameraSettings) {
        self.settings = settings
    }
    
    init() {
        
    }
    
    var x: Float {
        settings.eye.x
    }
    
    var y: Float {
        settings.eye.y
    }
    
    var z: Float {
        settings.eye.z
    }
    
    var aspectRatio: Float {
        settings.aspectRatio
    }
    
    var fov: Float {
        radians_from_degrees(settings.fovDegrees)
    }
    
    var nearPlane: Float {
        settings.nearZ
    }
    
    var farPlane: Float {
        settings.farZ
    }
    
    var cameraSettings: CameraSettings {
        settings
    }
    
    var viewMatrix: simd_float4x4 {
        return makeLookAtMatrix(
            eye: cameraSettings.eye,         // cámara en Z+
            center: cameraSettings.center,  // mirando al origen
            up: cameraSettings.up          // eje Y hacia arriba
        )

    }
    
    var modelMatrix: simd_float4x4 {
        return rotationMatrixX(degrees: 0)
    }
    
    var projectionMatrix: simd_float4x4 {
        return makePerspectiveMatrix(
            fovY: radians_from_degrees(settings.fovDegrees),
            aspect: aspectRatio,
            nearZ: nearPlane,
            farZ: farPlane
        )
    }
    
    var screenLimits: SIMD2<Float> {
        return SIMD2<Float>(
            x: -aspectRatio * tan(radians_from_degrees(settings.fovDegrees) / 2.0),
            y: tan(radians_from_degrees(settings.fovDegrees) / 2.0)
        )
    }
    
    func update(deltaTime: Float) {
         
    }
    
    func lookAt(x: Float, y: Float, z: Float) {
        settings.center = SIMD3<Float>(x: x, y: y, z: z)
    }

    
    func move(forward: Bool, backward: Bool, left: Bool, right: Bool) {
        
    }
    
    func strafe(left: Bool, right: Bool) {
        
    }
    
    func pitch(up: Bool, down: Bool) {
        
    }
    
    func yaw(left: Bool, right: Bool) {
        
    }
    
    func fly(up: Bool, down: Bool) {
        
    }
}
