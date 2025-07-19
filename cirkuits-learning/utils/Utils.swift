//
//  utils.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import MetalKit

func makeDefaultRenderPipeline(device: MTLDevice, vertexName: String, fragmentName: String) -> MTLRenderPipelineState {
    let pipelineState: MTLRenderPipelineState!
    let library = device.makeDefaultLibrary()!
    let vertexFunction = library.makeFunction(name: vertexName)!
    let fragmentFunction = library.makeFunction(name: fragmentName)!
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    // -- First attribute is position
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0 // -- position starts at 0 index in buffer
    vertexDescriptor.attributes[0].bufferIndex = 0
    // --- Second attribute is color
    vertexDescriptor.attributes[1].format = .float4
    vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride // -- color starts when position arr length ends
    vertexDescriptor.attributes[1].bufferIndex = 0
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    
    do {
        pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
        fatalError("Error building pipeline state: \(error)")
    }
    return pipelineState
}
