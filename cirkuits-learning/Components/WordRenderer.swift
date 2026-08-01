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
    private var currentFoo: WordFoo!
    var CurrentFoo: WordFoo {
        get { currentFoo }
        set {
            currentFoo = newValue;
            do {
                try layoutManager.setWord(word: currentFoo.Word)
            } catch {
                print(error.localizedDescription.cString(using: .utf8)!)
            }
        }
    }
    private var uniformBuffer: MTLBuffer?

    /// Optional per-letter override applied on top of the layout transform at
    /// draw time. Receives the letter's index, the letter itself and its layout
    /// matrix, and returns the matrix to draw with.
    ///
    /// Lets a scene animate letters without the layout manager knowing about it
    /// — nil in the game, set by the sandbox for its exit animation.
    var letterTransformModifier: ((Int, Letter, simd_float4x4) -> simd_float4x4)?

    /// World-space centre of the word currently on stage, for framing a camera.
    var wordCenter: SIMD3<Float> { layoutManager.wordCenter }


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
    
    func update(deltaTime: Float) {
        layoutManager.update(deltaTime: deltaTime)
    }
   
    func cleanUp() {
        layoutManager.cleanStageLetters()
    }
    
    func render(encoder: MTLRenderCommandEncoder,
                viewMatrix: simd_float4x4,
                projectionMatrix: simd_float4x4) {
        
        encoder.setRenderPipelineState(pipelineState)
        guard let uniformBuffer = uniformBuffer else { return }
        
        let letters = layoutManager.getLetters()
        let transforms = layoutManager.getLetterTransforms()
        let uniformsPointer = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: transforms.count)
        for(index, transform) in transforms.enumerated() {
            var modelMatrix = transform
            if let modifier = letterTransformModifier, index < letters.count {
                modelMatrix = modifier(index, letters[index], transform)
            }
            uniformsPointer[index] = Uniforms(
                projectionMatrix:projectionMatrix,
                viewMatrix: viewMatrix,
                modelMatrix: modelMatrix,
                // Normals don't survive a model matrix the way positions do —
                // they need its inverse-transpose. Identity-equivalent while a
                // letter is only translated, but essential once one rotates.
                normalMatrix: simd_transpose(simd_inverse(modelMatrix))
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
