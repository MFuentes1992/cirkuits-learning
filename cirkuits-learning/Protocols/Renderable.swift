//
//  Renderable.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import MetalKit

protocol Renderable {
    func setPipeLineState(pipeLineState: MTLRenderPipelineState)
    var pipelineState: MTLRenderPipelineState { get }
    func encode(encoder: MTLRenderCommandEncoder)
}

