//
//  Letter.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 06/08/25.
//
import MetalKit

class Letter: Renderable {
    var mesh: Mesh!
    var uniforms: Uniforms!
    var uniformBuffer: MTLBuffer!
    var _pipeLineState: MTLRenderPipelineState!
    
    
    init(letter: String, device: MTLDevice, modelViewProjectionMatrix: simd_float4x4, modelMatrix: simd_float4x4) {
        guard let url = Bundle.main.url(forResource: "\(letter)_letter", withExtension: "obj") else {
            fatalError("No se pudo encontrar letter en el bundle.")
        }
        mesh = ObjLoader.loadMesh(from: url, device: device)!;
        uniforms =  Uniforms(
            modelViewProjectionMatrix: modelViewProjectionMatrix,
            modelMatrix: modelMatrix,
            lightPosition: SIMD3<Float>(0, 0, 10),
            cameraPosition: SIMD3<Float>(0, 0, 500)
        )
        buildBuffers(uniforms: uniforms, device: device)
    }
    
    func buildBuffers(uniforms: Uniforms, device: MTLDevice) {
        var _uniforms = uniforms
        uniformBuffer = device.makeBuffer(bytes: &_uniforms, length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)!
    }
    
    func setPipeLineState(pipeLineState: any MTLRenderPipelineState) {
        _pipeLineState = pipeLineState
    }
    
    var pipelineState: any MTLRenderPipelineState {
        return _pipeLineState
    }
        
    func encode(encoder: any MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(_pipeLineState)
        encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: mesh.indexCount,
                                            indexType: .uint16,
                                            indexBuffer: mesh.indexBuffer,
                                            indexBufferOffset: 0)
    }
}
