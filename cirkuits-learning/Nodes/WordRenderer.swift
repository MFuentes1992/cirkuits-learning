//
//  WordRenderer.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//
import MetalKit

class WordRenderer {
    private let device: MTLDevice
    private let pipelineState: MTLRenderPipelineState
    private let layoutManager: WordLayoutManager
    private var uniformBuffer: MTLBuffer?
        
    init(device: MTLDevice,
         screenWidth: Float) {
        self.device = device
        
        let config = WordLayoutConfig(screenWidth: screenWidth)
        self.layoutManager = WordLayoutManager(config: config, device: device)
        pipelineState = makeObjectRenderPipeline(device: device, vertexName: "obj_vertex_shader", fragmentName: "obj_fragment_shader")
        setupUniformBuffer()
    }
    
    private func setupUniformBuffer() {
        let uniformsSize = MemoryLayout<Uniforms>.size * 64
        uniformBuffer = device.makeBuffer(length: uniformsSize, options: [.storageModeShared])
    }
    
    func setWord(_ word: String) {
        do{
           try  layoutManager.setWord(word: word)
        } catch {
                print(error.localizedDescription.cString(using: .utf8)!)
        }
    }
    
    func update(deltaTime: Float) {
        layoutManager.update(deltaTime: deltaTime)
    }
    
    func render(encoder: MTLRenderCommandEncoder,
                viewMatrix: simd_float4x4,
                projectionMatrix: simd_float4x4) {
        
        encoder.setRenderPipelineState(pipelineState)
        guard let uniformBuffer = uniformBuffer else { return }
        
        let transforms = layoutManager.getLetterTransforms()
        let uniformsPointer = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: transforms.count)
        for(index, transform) in transforms.enumerated() {
            uniformsPointer[index] = Uniforms(
                projectionMatrix:projectionMatrix,
                viewMatrix: viewMatrix,
                modelMatrix: transform,
                lightPosition: SIMD3<Float>(0, 0, 10),
                cameraPosition: SIMD3<Float>(0, 0, 500)
            )
        }
            
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        for (index,letter) in layoutManager.getLetters().enumerated() {
            if(letter.mesh == nil){
                continue
            }
            encoder.setVertexBuffer(letter.mesh.vertexBuffer, offset: 0, index: 0)
            encoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: letter.mesh.indexCount,
                                            indexType: .uint16,
                                            indexBuffer: letter.mesh.indexBuffer,
                                            indexBufferOffset: 0,
                                            instanceCount: 1,
                                            baseVertex: 0,
                                            baseInstance: index)
        }
    }
}
