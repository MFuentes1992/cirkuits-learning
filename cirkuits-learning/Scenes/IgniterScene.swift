//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import simd
import MetalKit

class IgniterScene: SceneProtocol {
    var scrambler: Scrambler!
    var cameraSettings: CameraSettings!
    var camera: Camera!
    // let animationController: AnimationController! = AnimationController()
    var device: MTLDevice!

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero

    init(device: MTLDevice) {
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
        scrambler = Scrambler(word: "AUSCHLESEN", device: device, camera: camera)
        print("Camera bounds: \(camera.calculateScreenLimits(at: 100.0))")
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
        // animationController.updateUniforms(currentTime: CACurrentMediaTime())
        // var timeUniforms = animationController.getUniforms()
        // encoder.setVertexBytes(&timeUniforms, length: MemoryLayout<TimeUniforms>.stride, index: 2)
        scrambler.encode(encoder: encoder)
    }
    
}
