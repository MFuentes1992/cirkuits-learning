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
    private var timerLabel: UILabel!
    private var scoreLabel: UILabel!
    private var pauseButton: UIButton!
    private var timeRemaining: TimeInterval = 60.0
    private var gameTimer: Timer?
    private var renderer: Renderer!
    private var comboGauge: ComboGauge!
    private var gameState = GameState()
    private var isPaused = false
    
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
        metalView.clearColor = MTLClearColorMake(0.423, 0.231, 0.66, 1)
        view.addSubview(metalView)

        renderer = Renderer(device: metalView.device, view: metalView, gameState: self.gameState)
        metalView.delegate = renderer
        print("App -> loaded!")
        // Gestos
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch)))
    }
    
    func setupHUD() {
        timerLabel = UILabel()
        timerLabel.font = .monospacedSystemFont(ofSize: 32, weight: .bold)
        timerLabel.textColor = .gray
        timerLabel.shadowColor = .darkGray
        timerLabel.shadowOffset = CGSize(width: 2, height: 2)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        
        // Score label
        scoreLabel = UILabel()
        scoreLabel.font = .monospacedSystemFont(ofSize: 32, weight: .bold)
        scoreLabel.textColor = .gray
        scoreLabel.shadowColor = .darkGray
        scoreLabel.shadowOffset = CGSize(width: 2, height: 2)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.text = "000"
        view.addSubview(scoreLabel)
        
        // Pause Button
        pauseButton = UIButton(type: .system)
        let pauseConfiguration = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        pauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: pauseConfiguration), for: .normal)
        pauseButton.tintColor = .systemGray
        pauseButton.addTarget(self, action: #selector(pauseGame), for: .touchUpInside)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pauseButton)
                
        comboGauge = ComboGauge()
        comboGauge.translatesAutoresizingMaskIntoConstraints = false
        gameState.setGaugeController(gauge: comboGauge)
        view.addSubview(comboGauge)
                
        // Constraints
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            pauseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            pauseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            comboGauge.widthAnchor.constraint(equalToConstant: 120),
            comboGauge.heightAnchor.constraint(equalToConstant: 140),
            comboGauge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            comboGauge.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
            
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
        updateScoreDisplay()
    }
    
    func updateTimerDisplay() {
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining) % 60
        let formattedTimerString = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.text = formattedTimerString
    }
    
    func updateScoreDisplay() {
        let formattedScoreString = String(format: "0%.0f", renderer.sceneManager.getScore())
        scoreLabel.text = formattedScoreString
    }
    
    @objc func pauseGame() {
        isPaused = !isPaused
        renderer.handlePauseEvent()
        let iconName = isPaused ? "play.circle.fill" : "pause.circle.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        pauseButton.setImage(image, for: .normal)
        
        // Pause/resume game
        if isPaused {
            gameTimer?.invalidate()
            // Pause Metal rendering if needed
        } else {
            startTimer()
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        renderer.handlePanEvents(gesture: gesture, location: location)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        renderer.handlePinchEvents(gesture: gesture)
    }
}
