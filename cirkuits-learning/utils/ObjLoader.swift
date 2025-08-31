//
//  ObjLoader.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 04/08/25.
//
import MetalKit

class ObjLoader {
    static func loadMesh(from url: URL, device: MTLDevice) -> (Mesh, minX: Float, maxX: Float) {
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt16] = []

        let content = try! String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let sanitizedLine = line.replacingOccurrences(of: "\t\t", with: "", options: NSString.CompareOptions.literal, range: nil)
            let tokens = sanitizedLine.split(separator: " ")
            guard let type = tokens.first else { continue }

            switch type {
            case "v":
                let x = Float(tokens[1])!
                let y = Float(tokens[2])!
                let z = Float(tokens[3])!
                positions.append(SIMD3<Float>(x, y, z))
                if x < minX {
                    minX = x
                }
                if x > maxX {
                    maxX = x
                }
            case "vn":
                let x = Float(tokens[1])!
                let y = Float(tokens[2])!
                let z = Float(tokens[3])!
                normals.append(SIMD3<Float>(x, y, z))
            case "f":
                for i in 1..<tokens.count {
                    let part = tokens[i].replacingOccurrences(of: "\t", with: "", options: NSString.CompareOptions.literal, range: nil)
                    let vertexIndex = UInt16(part)! - 1
                    indices.append(vertexIndex)
                }
            default:
                break
            }
        }


        var vertices: [ObjVertex] = []
        for i in 0..<positions.count {
            let v = ObjVertex(position: positions[i],
                           normal: i < normals.count ? normals[i] : SIMD3<Float>(0, 0, 1))
            vertices.append(v)
        }

        let vertexBuffer = device.makeBuffer(bytes: vertices,
                                             length: MemoryLayout<ObjVertex>.stride * vertices.count,
                                             options: [])
        let indexBuffer = device.makeBuffer(bytes: indices,
                                            length: MemoryLayout<UInt16>.stride * indices.count,
                                            options: [])

        return (Mesh(vertexBuffer: vertexBuffer!,
                    indexBuffer: indexBuffer!,
                    indexCount: indices.count), minX, maxX)
    }
}
