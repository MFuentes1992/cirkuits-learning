//
//  CubeMesh.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 28/07/25.
//

import MetalKit

class CubeMesh {
    let vertexBuffer: MTLBuffer
    init(device: MTLDevice) {
        let vertices: [SIMD3<Float>] = [
            // Front
            [-1, -1,  1], [1, -1, 1], [1, 1, 1],
            [-1, -1,  1], [1, 1, 1], [-1, 1, 1],
            // Back
            [-1, -1, -1], [-1, 1, -1], [1, 1, -1],
            [-1, -1, -1], [1, 1, -1], [1, -1, -1],
            // Left
            [-1, -1, -1], [-1, -1, 1], [-1, 1, 1],
            [-1, -1, -1], [-1, 1, 1], [-1, 1, -1],
            // Right
            [1, -1, -1], [1, 1, -1], [1, 1, 1],
            [1, -1, -1], [1, 1, 1], [1, -1, 1],
            // Top
            [-1, 1, -1], [-1, 1, 1], [1, 1, 1],
            [-1, 1, -1], [1, 1, 1], [1, 1, -1],
            // Bottom
            [-1, -1, -1], [1, -1, -1], [1, -1, 1],
            [-1, -1, -1], [1, -1, 1], [-1, -1, 1],
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD3<Float>>.stride, options: [])!
    }
    
    func encode(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0) //TODO: Adjust buffers to be queued correctly in the shaders
    }
}
