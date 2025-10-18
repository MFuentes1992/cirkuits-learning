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
    var lightPosition: SIMD3<Float>
    var cameraPosition: SIMD3<Float>
}
