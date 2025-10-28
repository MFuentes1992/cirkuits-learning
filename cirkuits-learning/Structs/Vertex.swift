//
//  Vertex.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}


struct SimpleVertex {
    var position: SIMD3<Float>
}

struct ObjVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}
