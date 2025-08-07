//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import simd
import MetalKit

class IgniterScene: SceneProtocol {
    
    var plain: Plain!
    var letter: Letter!
    var device: MTLDevice!

    var meshPipeLine: MTLRenderPipelineState!
    var plainPipeLine: MTLRenderPipelineState!
    var cameraPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
     // -- Camera setup
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var aspectRatio: Float
    var projectionMatrix: simd_float4x4
    
    init(device: MTLDevice) {
        self.device = device
        plain = Plain(device: device)
        plainPipeLine = makeDefaultRenderPipeline(device: device, vertexName: "vertex_shader", fragmentName: "fragment_shader")
        plain.setPipeLineState(pipeLineState: plainPipeLine)
        
        // -- Camera setup
        modelMatrix = rotationMatrixX(degrees: 0)
        viewMatrix = makeLookAtMatrix(
            eye: SIMD3(0, 0, 100),       // cámara en Z+
            center: SIMD3(0, 0, 0),      // mirando al origen
            up: SIMD3(0, 1, 0)           // eje Y hacia arriba
        )
        aspectRatio = Float(19.5/9)
        projectionMatrix = makePerspectiveMatrix(fovY: radians_from_degrees(60),aspect: aspectRatio,
                                                     nearZ: 1.0,
                                                     farZ: 1000.0)
        let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix
        
        // -- 3D model pipeline
        letter = Letter(letter: "o", device: device, modelViewProjectionMatrix: mvpMatrix, modelMatrix: modelMatrix)
        meshPipeLine = makeObjectRenderPipeline(device: device, vertexName: "obj_vertex_shader", fragmentName: "obj_fragment_shader")
        letter.setPipeLineState(pipeLineState: meshPipeLine)
    }
    
        
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        if gesture.state == .began {
            lastPanLocation = location
        } else if gesture.state == .changed {
            let delta = CGPoint(x: location.x - lastPanLocation.x, y: location.y - lastPanLocation.y)
            // orbitCamera.rotate(deltaTheta: Float(delta.x) * 0.005, deltaPhi: Float(delta.y) * 0.005)
            lastPanLocation = location
        }
    }
    
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            // orbitCamera.zoom(delta: Float(1 - gesture.scale) * 2.0)
            gesture.scale = 1.0
        }
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        letter.encode(encoder: encoder)
        // -- Plain
        // plain.encode(encoder: encoder)
        // -- Letter H
        
        
    }
    
    
}
