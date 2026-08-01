//
//  Uniforms.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 04/08/25.
//
import simd

struct Uniforms {
    // var modelViewProjectionMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
    /// Inverse-transpose of `modelMatrix`, for carrying normals into world
    /// space. Field order must stay in step with the `Uniforms` struct in
    /// `Shader_Obj.metal`.
    var normalMatrix: simd_float4x4
}
