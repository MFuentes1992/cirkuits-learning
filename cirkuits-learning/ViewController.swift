//
//  ViewController.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 04/06/25.
//
import UIKit
import MetalKit

class ViewController: UIViewController {
    
    /* var mtkView: MTKView {
        return view as! MTKView
    }
    var renderer: MTKViewDelegate!
    var timeLabel: UILabel!
    
    func setupTimeLabel() {
        timeLabel = UILabel()
        timeLabel.font = .systemFont(ofSize: 24)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTimeLabel()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0.5, green: 0.4, blue: 0.21, alpha: 1.0)
        renderer = Renderer(device: mtkView.device)
        mtkView.delegate = renderer.self
    } */
    
    var metalView: MTKView!
    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal no es compatible con este dispositivo")
        }

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.device = device
        metalView.clearColor = MTLClearColorMake(1, 1, 1, 0.5)
        // metalView.colorPixelFormat = .bgra8Unorm
        // metalView.depthStencilPixelFormat = .depth32Float
        view.addSubview(metalView)

        renderer = Renderer(device: metalView.device)
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
