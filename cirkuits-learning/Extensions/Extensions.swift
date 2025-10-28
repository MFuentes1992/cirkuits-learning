//
//  float4x4.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 31/08/25.
//
import simd

extension float4x4 {
    init(translation t: SIMD3<Float>) {
        self = matrix_identity_float4x4
        self.columns.3 = SIMD4<Float>(t.x, t.y, t.z, 1)
    }
    
    init(scaling s: SIMD3<Float>) {
        self = matrix_identity_float4x4
        self.columns.0 = SIMD4<Float>(s.x, 0, 0, 0)
        self.columns.1 = SIMD4<Float>(0, s.y, 0, 0)
        self.columns.2 = SIMD4<Float>(0, 0, s.z, 0)
    }
    
    init(rotationX angle: Float) {
        self = matrix_identity_float4x4
        self.columns.1.y = cos(angle)
        self.columns.1.z = -sin(angle)
        self.columns.2.y = sin(angle)
        self.columns.2.z = cos(angle)
    }
    
    init(rotationY angle: Float) {
        self = matrix_identity_float4x4
        self.columns.0.x = cos(angle)
        self.columns.0.z = sin(angle)
        self.columns.2.x = -sin(angle)
        self.columns.2.z = cos(angle)
    }
    
    init(rotationZ angle: Float) {
        self = matrix_identity_float4x4
        self.columns.0.x = cos(angle)
        self.columns.0.y = -sin(angle)
        self.columns.1.x = sin(angle)
        self.columns.1.y = cos(angle)
    }
}
