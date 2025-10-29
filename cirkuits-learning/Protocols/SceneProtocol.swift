//
//  SceneProtocol.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import MetalKit

protocol SceneProtocol {
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint)
    func handlePinchGesture(gesture: UIPinchGestureRecognizer)
    func encode(encoder: MTLRenderCommandEncoder)
    func togglePaused()
}
