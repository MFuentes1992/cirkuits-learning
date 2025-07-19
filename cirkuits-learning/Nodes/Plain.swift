//
//  Plane.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import MetalKit

class Plain: Renderable {
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var _pipelineState: MTLRenderPipelineState!
    
    var vertices: [Vertex] = [
        Vertex(position: SIMD3(-1, 1, 0), color: SIMD4(1, 0, 0, 1)),
        Vertex(position: SIMD3(-1, -1, 0), color: SIMD4(0, 1, 0, 1)),
        Vertex(position: SIMD3(1, -1, 0), color: SIMD4(0, 0, 1, 1)),
        Vertex(position: SIMD3(1, 1, 0), color: SIMD4(1, 0, 1, 1)),
    ]
    
    var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    
    init(device: MTLDevice){
        buildBuffers(device: device)
    }
        
    func setPipeLineState(pipeLineState: MTLRenderPipelineState) {
        _pipelineState = pipeLineState
    }
    
    var pipelineState: MTLRenderPipelineState {
        return _pipelineState
    }
    
    func buildBuffers(device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.size * indices.count, options: [])
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(_pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
}
