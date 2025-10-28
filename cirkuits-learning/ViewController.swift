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
    var timerLabel: UILabel!
    var scoreLabel: UILabel!
    var timeRemaining: TimeInterval = 60.0
    var gameTimer: Timer?
    
    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetalView()
        setupHUD()
        startTimer()
    }
    
    func setupMetalView() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal no es compatible con este dispositivo")
        }

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.device = device
        metalView.clearColor = MTLClearColorMake(1, 1, 1, 0.5)
        // metalView.colorPixelFormat = .bgra8Unorm
        // metalView.depthStencilPixelFormat = .depth32Float
        view.addSubview(metalView)

        renderer = Renderer(device: metalView.device, view: metalView)
        metalView.delegate = renderer
        print("App -> loaded!")
        // Gestos
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch)))
    }
    
    func setupHUD() {
        timerLabel = UILabel()
        timerLabel.font = .monospacedSystemFont(ofSize: 48, weight: .bold)
        timerLabel.textColor = .gray
        timerLabel.shadowColor = .darkGray
        timerLabel.shadowOffset = CGSize(width: 2, height: 2)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        
        // Score label
        scoreLabel = UILabel()
        scoreLabel.font = .monospacedSystemFont(ofSize: 32, weight: .bold)
        scoreLabel.textColor = .yellow
        scoreLabel.shadowColor = .black
        scoreLabel.shadowOffset = CGSize(width: 2, height: 2)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        updateTimerDisplay()
    }
    
    func startTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
            [weak self] _ in
                        self?.updateTimer()
        }
    }
    
    func updateTimer() {
        timeRemaining -= 0.1
        if timeRemaining <= 0 {
            timeRemaining = 0
            gameTimer?.invalidate()
            
        }
        updateTimerDisplay()
    }
    
    func updateTimerDisplay() {
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining) % 60
        let formattedTimerString = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.text = formattedTimerString
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        renderer.handlePanEvents(gesture: gesture, location: location)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        renderer.handlePinchEvents(gesture: gesture)
    }
}
