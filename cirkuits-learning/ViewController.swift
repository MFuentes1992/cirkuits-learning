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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetalView()
    }
    
    func setupMetalView() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal no es compatible con este dispositivo")
        }
        // The root view is already an MTKView (set in _Main.storyboard), so
        // render into it directly instead of nesting a second, inset MTKView.
        guard let metalView = view as? MTKView else {
            fatalError("El view raíz debe ser un MTKView")
        }
        self.metalView = metalView
        metalView.device = device
        metalView.clearColor = MTLClearColorMake(0.423, 0.231, 0.66, 1)

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
