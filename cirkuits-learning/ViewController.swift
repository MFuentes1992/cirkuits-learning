//
//  ViewController.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 04/06/25.
//
import UIKit
import MetalKit
import SwiftUI

class ViewController: UIViewController {
    private var metalView: MTKView!
    private var renderer: Renderer!
    private var backgroundView: SwirlPatternView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetalView()
    }

    func setupMetalView() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal no es compatible con este dispositivo")
        }
        metalView = MTKView(frame: view.bounds, device: device)
        metalView.device = device
        metalView.isOpaque = false
        metalView.backgroundColor = .clear
        metalView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        // Without a depth buffer, triangles land in submission order and the
        // back of an extruded letter paints over its front — the letters read
        // as hollow. MTKView allocates and clears the texture once this is set.
        metalView.depthStencilPixelFormat = depthPixelFormat
        metalView.clearDepth = 1.0
        view.addSubview(metalView)

        renderer = Renderer(device: device, view: metalView)
        metalView.delegate = renderer
        print("App -> loaded!")
        // Gestos
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch)))
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        renderer.handlePanEvents(gesture: gesture, location: location)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        renderer.handlePinchEvents(gesture: gesture)
    }
}
