//
//  Scrambler.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 06/08/25.
//
import MetalKit
import simd

class Scrambler {
    
    var letters: Array<Letter> = [];
    var letterB: Letter!
    var camera: Camera!
    var word: String!
    
    init(word: String, device: MTLDevice, camera: Camera ) {
        let center = word.count/2
        let normWord = word.lowercased()
        let gap: Float = 21.0
        self.camera = camera
        var j: Int = center
        var k: Int = center
        var lModelMatrix = camera.modelMatrix
        var rModelMatrix = camera.modelMatrix
        
        let pipeline = makeObjectRenderPipeline(device: device, vertexName: "obj_vertex_shader", fragmentName: "obj_fragment_shader")
        for i in 0...(word.count / 2) {
            lModelMatrix.columns.3 = SIMD4(Float(i) * -gap, 0.0, 0, 1.0)
            rModelMatrix.columns.3 = SIMD4(Float(k - center) * gap, 0.0, 0, 1.0)
            let lMvpMatrix = camera.projectionMatrix * camera.viewMatrix * lModelMatrix
            let rMvpMatrix = camera.projectionMatrix * camera.viewMatrix * rModelMatrix
            
            let lLetter = Letter(letter: String(normWord.dropFirst(j).prefix(1)),
                                device: device, modelViewProjectionMatrix: lMvpMatrix, modelMatrix: lModelMatrix)
            let rLetter = Letter(letter: String(normWord.dropFirst(k).prefix(1)),
                                device: device, modelViewProjectionMatrix: rMvpMatrix, modelMatrix: rModelMatrix)
            lLetter.setPipeLineState(pipeLineState: pipeline)
            rLetter.setPipeLineState(pipeLineState: pipeline)
            letters.append(lLetter)
            letters.append(rLetter)
            print("\(Float(i) * -gap) \(j) \(k)")
            j = max(0, j - 1)
            k = min(word.count - 1, k + 1)
        }
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        for letter in letters {
            letter.encode(encoder: encoder)
        }
    }
    
}
