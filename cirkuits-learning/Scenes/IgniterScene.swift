//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import simd
import MetalKit

class IgniterScene: SceneProtocol {
    var wordRenderer: WordRenderer!
    var cameraSettings: CameraSettings!
    var camera: Camera!
    var device: MTLDevice!

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero

    init(device: MTLDevice, view: MTKView) {
        self.device = device
        cameraSettings = CameraSettings(
            eye: SIMD3<Float>(0,0,100),
            center: SIMD3<Float>(0,0,0),
            up: SIMD3<Float>(0,1,0),
            fovDegrees: 60.0,
            aspectRatio: 19.5/9,
            nearZ: 1.0,
            farZ: 1000.0)
        
        camera = Camera(settings: cameraSettings)
        wordRenderer = WordRenderer(device: device, screenWidth: Float(view.bounds.width))
        wordRenderer.setWord("Hello World my name is marco")
    }
    
    
    
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        if gesture.state == .began {
            lastPanLocation = location
        } else if gesture.state == .changed {
            let delta = CGPoint(x: location.x - lastPanLocation.x, y: location.y - lastPanLocation.y)
            lastPanLocation = location
        }
    }
    
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            gesture.scale = 1.0
        }
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        wordRenderer.update(deltaTime: 1.0/60.0)
        // wordRenderer.update(deltaTime: 0.0)
        wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }
    
}
