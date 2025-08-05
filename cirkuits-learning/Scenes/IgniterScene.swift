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
    var mesh: Mesh!
    var device: MTLDevice!
    // var orbitCamera: OrbitCamera!
    var meshPipeLine: MTLRenderPipelineState!
    var plainPipeLine: MTLRenderPipelineState!
    var cameraPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
     // -- Camera setup
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var aspectRatio: Float
    var projectionMatrix: simd_float4x4
    var uniforms: Uniforms!
    var uniformBuffer: MTLBuffer!
    
    init(device: MTLDevice) {
        self.device = device
        plain = Plain(device: device)
        // orbitCamera = OrbitCamera()
        plainPipeLine = makeDefaultRenderPipeline(device: device, vertexName: "vertex_shader", fragmentName: "fragment_shader")
        plain.setPipeLineState(pipeLineState: plainPipeLine)
        
        // -- Load 3D model
        meshPipeLine = makeObjectRenderPipeline(device: device, vertexName: "obj_vertex_shader", fragmentName: "obj_fragment_shader")
        guard let url = Bundle.main.url(forResource: "w_letter", withExtension: "obj") else {
            fatalError("No se pudo encontrar letter en el bundle.")
        }
        
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
        uniforms = Uniforms(
            modelViewProjectionMatrix: mvpMatrix,
            modelMatrix: modelMatrix,
            lightPosition: SIMD3<Float>(0, 0, 10),
            cameraPosition: SIMD3<Float>(0, 0, 500)
        )
        mesh = ObjLoader.loadMesh(from: url, device: device)!;
        uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)!
        
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
        /* let aspect = Float(19.5/9)
        let projectionMatrix = float4x4(perspectiveDegreesFov: 60, aspectRatio: aspect, nearZ: 0.1, farZ: 100)
        let viewMatrix = orbitCamera.viewMatrix()
        var mvpMatrix = projectionMatrix * viewMatrix */
        encoder.setRenderPipelineState(meshPipeLine)
        
        /* encoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.size, index: 1)
        encoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.size, index: 2)
        encoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.size, index: 3) */
        
        encoder.setVertexBuffer(mesh.vertexBuffer, offset:0, index: 0);
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: mesh.indexCount,
                                            indexType: .uint16,
                                            indexBuffer: mesh.indexBuffer,
                                            indexBufferOffset: 0)
        

        // -- Plain
        // plain.encode(encoder: encoder)
        // -- Letter H
        
        
    }
    
    
}
