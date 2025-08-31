//
//  Letter.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 06/08/25.
//
import simd
import MetalKit

class Letter: Renderable {
    var mesh: Mesh!
    var margin: Float = 0
    var minX: Float = 0
    var maxX: Float = 0
    var width: Float { return maxX - minX }
    var uniforms: Uniforms!
    var _modelMatrix: float4x4!
    var uniformBuffer: MTLBuffer!
    var _pipeLineState: MTLRenderPipelineState!
    
    
    init(letter: String, device: MTLDevice, viewMatrix: simd_float4x4, projectionMatrix: simd_float4x4, modelMatrix: float4x4, margin: Float = 0) {
        guard let url = Bundle.main.url(forResource: "\(letter)_letter", withExtension: "obj") else {
            fatalError("No se pudo encontrar letter en el bundle.")
        }
        self._modelMatrix = modelMatrix
        self.margin = margin
        
        let result = ObjLoader.loadMesh(from: url, device: device);
        mesh = result.0
        minX = result.1
        maxX = result.2
        
        print("Letter: \(letter), Minx: \(minX), Maxx: \(maxX), Width: \(width), X: \(_modelMatrix.columns.3.x)")
        /* _modelMatrix.columns.3.x = _modelMatrix.columns.3.x * width */
        
        uniforms =  Uniforms(
            modelViewProjectionMatrix: projectionMatrix * viewMatrix * _modelMatrix,
            modelMatrix: _modelMatrix,
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
    
    var modelMatrix: float4x4 {
        return _modelMatrix
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
