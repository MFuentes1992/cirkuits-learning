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
        let gap: Float = 10
        var lastLeftPosition: Float = 0.0
        var lastRightPosition: Float = 0.0
        self.camera = camera
        var j: Int = center
        var k: Int = center + 1
        
        let pipeline = makeObjectRenderPipeline(device: device, vertexName: "obj_vertex_shader", fragmentName: "obj_fragment_shader")
        for _ in 0...(word.count / 2) {
            // ----- Left letters
            let lModelMatrix = makeModelMatrix(position: SIMD3(lastLeftPosition, 0, 0), rotation: SIMD3(0, 0, 0), scale: SIMD3(1, 1, 1))
            let lLetter = Letter(letter: String(normWord.dropFirst(j).prefix(1)),
                                 device: device, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix,modelMatrix: lModelMatrix)
            
            lLetter.setPipeLineState(pipeLineState: pipeline)
            lastLeftPosition = lastLeftPosition - Float(lLetter.width) - gap
            letters.append(lLetter)
            
            j = max(0, j - 1)
            
            
            // ------ Right letters
            if(lastRightPosition == 0) {
                lastRightPosition = lLetter.width + gap
            }
                
            if(k < word.count) {
                let rModelMatrix = makeModelMatrix(position: SIMD3(lastRightPosition, 0, 0), rotation: SIMD3(0, 0, 0), scale: SIMD3(1, 1, 1))
                let rLetter = Letter(letter: String(normWord.dropFirst(k).prefix(1)),
                                    device: device, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix,modelMatrix: rModelMatrix)
                rLetter.setPipeLineState(pipeLineState: pipeline)
                lastRightPosition = lastRightPosition + Float(rLetter.width) + gap
                letters.append(rLetter)
                k = k + 1
            }
        }
        
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        for letter in letters {
            letter.encode(encoder: encoder)
        }
    }
    
}
