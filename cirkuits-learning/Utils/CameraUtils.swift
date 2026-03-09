//
//  CameraUtils.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 29/07/25.
//

import simd

func makePerspectiveMatrix(fovY: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
    let yScale = 1 / tan(fovY * 0.5)
    let xScale = yScale / aspect
    let zRange = farZ - nearZ
    let zScale = -(farZ + nearZ) / zRange
    let wzScale = -2 * farZ * nearZ / zRange

    return simd_float4x4(columns: (
        SIMD4(xScale, 0, 0, 0),
        SIMD4(0, yScale, 0, 0),
        SIMD4(0, 0, zScale, -1),
        SIMD4(0, 0, wzScale, 0)
    ))
}

func matrix_float4x4_projection(degree: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
    let radians = degree * .pi / 180;
    let y = 1 / tan(radians * 0.5)
    let x = y / aspect
    let z = far / (far - near)
    
    var matrix = matrix_identity_float4x4
    matrix.columns.0.x = x
    matrix.columns.1.y = y
    matrix.columns.2.z = z
    matrix.columns.2.w = 1
    matrix.columns.3.z  = -(z * near)
    matrix.columns.3.w = 0
    
    return matrix
}

func make_perspective_right_hand(fovY: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
    let yScale = 1 / tan(fovY * 0.5)
    let xScale = yScale / aspect
    let zScale = farZ / (nearZ - farZ)
    return simd_float4x4(columns: (
        SIMD4(xScale, 0, 0, 0),
        SIMD4(0, yScale, 0, 0),
        SIMD4(0, 0, zScale, -1),
        SIMD4(0, 0, zScale * nearZ, 0)
    ))
}

func makeLookAtMatrix(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
    let z = normalize(eye - center)
    let x = normalize(cross(up, z))
    let y = cross(z, x)

    return simd_float4x4(columns: (
        SIMD4(x.x, y.x, z.x, 0),
        SIMD4(x.y, y.y, z.y, 0),
        SIMD4(x.z, y.z, z.z, 0),
        SIMD4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
    ))
}

func makeTranslationMatrix(x: Float, y: Float, z: Float) -> simd_float4x4 {
    var m = matrix_identity_float4x4
    m.columns.3 = SIMD4(x, y, z, 1)
    return m
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees * Float.pi) / 180.0
}


func rotationMatrixX(degrees: Float) -> simd_float4x4 {
    let radians = degrees * .pi / 180
    let cosA = cos(radians)
    let sinA = sin(radians)

    return simd_float4x4(
        SIMD4(1,    0,     0, 0),
        SIMD4(0, cosA, -sinA, 0),
        SIMD4(0, sinA,  cosA, 0),
        SIMD4(0,    0,     0, 1)
    )
}

func matrix_rotation(radians: Float, axis: simd_float3) -> simd_float4x4 {
    let axis = simd_normalize(axis);
    let ct = cos(radians);
    let st = sin(radians);
    let ci = 1 - ct;
    let x = axis.x;
    let y = axis.y;
    let z = axis.z;
    
    return simd_float4x4(
        simd_float4(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
        simd_float4(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
        simd_float4(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
        simd_float4(0,0,0,1)
    )
    
}

func makeModelMatrix(position: SIMD3<Float>,
                     rotation: SIMD3<Float>,
                     scale: SIMD3<Float>) -> float4x4 {
    
    let translation = float4x4(translation: position)
    let scaling     = float4x4(scaling: scale)
    
    let rotationX   = float4x4(rotationX: rotation.x)
    let rotationY   = float4x4(rotationY: rotation.y)
    let rotationZ   = float4x4(rotationZ: rotation.z)
    
    // Orden típico: T * Rz * Ry * Rx * S
    return translation * rotationZ * rotationY * rotationX * scaling
}


func matrix_scale(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
    return simd_float4x4(
        simd_float4(x, 0, 0, 0),
        simd_float4(0, y, 0, 0),
        simd_float4(0, 0, z, 0),
        simd_float4(0, 0, 0, 1),
    )
}
