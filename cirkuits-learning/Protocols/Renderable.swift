//
//  Renderable.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import simd
import MetalKit

protocol Renderable {
    var pipelineState: MTLRenderPipelineState { get }
    var modelMatrix: float4x4 { get }
    
    func setPipeLineState(pipeLineState: MTLRenderPipelineState)
    func encode(encoder: MTLRenderCommandEncoder)
}

