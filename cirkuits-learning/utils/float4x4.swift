//
//  float4x4.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 21/07/25.
//

import simd

extension float4x4 {
    init(perspectiveDegreesFov fovY: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let y = 1 / tan(fovY * 0.5 * .pi / 180)
        let x = y / aspectRatio
        let z = farZ / (nearZ - farZ)
        self.init(SIMD4<Float>( x,  0,  0,  0),
                  SIMD4<Float>( 0,  y,  0,  0),
                  SIMD4<Float>( 0,  0,  z, -1),
                  SIMD4<Float>( 0,  0,  z * nearZ, 0))
    }

    init(lookAt eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) {
        let z = normalize(eye - target)
        let x = normalize(cross(up, z))
        let y = cross(z, x)

        let t = SIMD3<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye))

        self.init(
            SIMD4<Float>(x.x, y.x, z.x, 0),
            SIMD4<Float>(x.y, y.y, z.y, 0),
            SIMD4<Float>(x.z, y.z, z.z, 0),
            SIMD4<Float>(t.x,  t.y,  t.z,  1)
        )
    }
}
