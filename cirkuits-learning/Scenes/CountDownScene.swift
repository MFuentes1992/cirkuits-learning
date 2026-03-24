//
//  CountDownScene.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 22/03/26.
//
import MetalKit
import SwiftUI

class CountDownScene: SceneProtocol {
    private var countDownLabel: UILabel
    private var elapsedTime: TimeInterval = 0
    private var timer: TimeController
    private var nextScene: GameScenes
    private var requestScene: (GameScenes) -> Void
    
    init(parentView: UIView, gameState: GameState, requestScene: @escaping (GameScenes) -> Void, nextScene: GameScenes) {
        let lookAndFeel = UILayoutLookAndFeel(color: .white, foreColor: .darkGray, buttonSize: 32, fontSize: 32)
        // Countdown label
        countDownLabel = UILabel()
        countDownLabel.font = .monospacedSystemFont(ofSize: 42, weight: .bold)
        countDownLabel.textColor = lookAndFeel.color
        countDownLabel.shadowColor = lookAndFeel.foreColor
        countDownLabel.shadowOffset = CGSize(width: 2, height: 2)
        countDownLabel.translatesAutoresizingMaskIntoConstraints = false
        countDownLabel.text = "\(elapsedTime)"
        parentView.addSubview(countDownLabel)
        self.requestScene = requestScene
        self.nextScene = nextScene
        timer = gameState.Timer
        elapsedTime = 3.0
        
        NSLayoutConstraint.activate([
            countDownLabel.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            countDownLabel.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
        ])
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
    }
    
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            gesture.scale = 1.0
        }
    }
    
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        if elapsedTime <= 0  {
            // request scene change
            requestScene(nextScene)
        } else {
            let formattedScoreString = String(format: "%0.0f", elapsedTime)
            countDownLabel.text = formattedScoreString
        }
        elapsedTime -= Double(timer.getTickSeconds())
    }
}
