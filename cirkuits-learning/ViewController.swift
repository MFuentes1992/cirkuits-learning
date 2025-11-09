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

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.device = device
        metalView.clearColor = MTLClearColorMake(0.423, 0.231, 0.66, 1)
        view.addSubview(metalView)

        renderer = Renderer(device: metalView.device, view: metalView)
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
