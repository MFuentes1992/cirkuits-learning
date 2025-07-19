//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import MetalKit

class IgniterScene: SceneProtocol {
    var plain: Plain!
    var device: MTLDevice!
    var plainPipeLine: MTLRenderPipelineState!
    
    init(device: MTLDevice) {
        self.device = device
        plain = Plain(device: device)
        plainPipeLine = makeDefaultRenderPipeline(device: device, vertexName: "vertex_shader", fragmentName: "fragment_shader")
        plain.setPipeLineState(pipeLineState: plainPipeLine)
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        plain.encode(encoder: encoder)
    }
    
    
}
