//
//  Letter.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 06/08/25.
//
import simd
import MetalKit

class Letter {
    var mesh: Mesh!
    var margin: Float = 0
    var bbLeftX: Float = 0
    var bbRightX: Float = 0
    var width: Float { return bbRightX - bbLeftX }
    var uniformBuffer: MTLBuffer!
    var transform: simd_float4x4 = matrix_identity_float4x4

    init(letter: String, device: MTLDevice) {
        if(letter == " ") { return }
        guard let letterAsset = NSDataAsset(name: "\(letter.lowercased())_letter") else {
            fatalError("No se pudo encontrar letter en el assets bunddle. \(letter)")
        }
        guard let content = String(data: letterAsset.data, encoding: .ascii) else {
            fatalError("Cannot unwrap wavefront assets. \(letter)")
        }        
        let result = ObjLoader.loadMesh(content: content, device: device);
        mesh = result.0
        bbLeftX = result.1
        bbRightX = result.2
    }
    
    func getModel() -> Mesh {
        return mesh;
    }
}
