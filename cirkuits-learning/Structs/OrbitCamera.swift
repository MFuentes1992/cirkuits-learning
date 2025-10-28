//
//  OrbitCamera.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 21/07/25.
//

import simd

struct OrbitCamera {
    var radius: Float = 5.0
    var theta: Float = 0.0
    var phi: Float = .pi / 2
    var target = SIMD3<Float>(0, 0, 0)

    mutating func rotate(deltaTheta: Float, deltaPhi: Float) {
        theta += deltaTheta
        phi = min(.pi - 0.01, max(0.01, phi + deltaPhi))
    }

    mutating func zoom(delta: Float) {
        radius = max(1.0, radius + delta)
    }

    func position() -> SIMD3<Float> {
        let x = radius * sin(phi) * cos(theta)
        let y = radius * cos(phi)
        let z = radius * sin(phi) * sin(theta)
        return SIMD3<Float>(x, y, z) + target
    }

    func viewMatrix() -> float4x4 {
        return float4x4(translation: SIMD3<Float>(0, 0, 0))
        // return float4x4(lookAt: position(), target: target, up: SIMD3<Float>(0, 1, 0))
    }
}
