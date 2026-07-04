//
//  CountDownScene.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 22/03/26.
//
import MetalKit
import SwiftUI

class CountDownScene: SceneProtocol {
    private let countDownLabel = UILabel()
    private let ringView = UIView()
    private var elapsedTime: TimeInterval = 0
    private var timer: TimeController
    private var nextScene: GameScenes
    private var requestScene: (GameScenes) -> Void
    private var gameState: GameState!

    /// The integer currently on screen; drives one pop animation per change.
    private var lastShown: Int = -1

    /// Accent colour keyed by the number being shown, cycling through the
    /// Igniter palette so each tick feels distinct.
    private let accents: [Int: UIColor] = [
        3: IgniterPalette.teal,
        2: IgniterPalette.pink,
        1: IgniterPalette.bracketYellow,
    ]

    private let ringSize: CGFloat = 240

    init(parentView: UIView, gameState: GameState, requestScene: @escaping (GameScenes) -> Void, nextScene: GameScenes) {
        self.requestScene = requestScene
        self.nextScene = nextScene
        self.gameState = gameState
        self.timer = gameState.Timer
        self.elapsedTime = 3.0

        // Expanding ring pulse behind the number — echoes the menu's
        // sound-wave ripples.
        ringView.translatesAutoresizingMaskIntoConstraints = false
        ringView.backgroundColor = .clear
        ringView.layer.cornerRadius = ringSize / 2
        ringView.layer.borderWidth = 10
        ringView.isUserInteractionEnabled = false
        ringView.alpha = 0
        parentView.addSubview(ringView)

        // Big rounded "sticker" number: cream fill, coloured outline, soft
        // navy drop shadow.
        countDownLabel.textAlignment = .center
        countDownLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(countDownLabel)

        NSLayoutConstraint.activate([
            ringView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            ringView.widthAnchor.constraint(equalToConstant: ringSize),
            ringView.heightAnchor.constraint(equalToConstant: ringSize),

            countDownLabel.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            countDownLabel.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
        ])
    }

    // MARK: - Number styling

    /// System font with the rounded design, matching the game's playful UI.
    private func roundedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    private func styledNumber(_ value: Int, accent: UIColor) -> NSAttributedString {
        let shadow = NSShadow()
        shadow.shadowColor = IgniterPalette.navy.withAlphaComponent(0.45)
        shadow.shadowOffset = CGSize(width: 0, height: 6)
        shadow.shadowBlurRadius = 10

        return NSAttributedString(string: "\(value)", attributes: [
            .font: roundedFont(size: 180, weight: .black),
            .foregroundColor: IgniterPalette.cream,
            // Negative width => stroke *and* fill (the coloured outline).
            .strokeColor: accent,
            .strokeWidth: -7.0,
            .shadow: shadow,
        ])
    }

    /// Show a number with a spring pop plus an expanding ring pulse.
    private func showNumber(_ value: Int) {
        let accent = accents[value] ?? IgniterPalette.pink
        countDownLabel.attributedText = styledNumber(value, accent: accent)

        // Pop the number in.
        countDownLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        countDownLabel.alpha = 0
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.55, initialSpringVelocity: 0.6,
                       options: .curveEaseOut) {
            self.countDownLabel.transform = .identity
            self.countDownLabel.alpha = 1
        }

        // Ripple the ring outward and fade it.
        ringView.layer.borderColor = accent.cgColor
        ringView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        ringView.alpha = 0.9
        UIView.animate(withDuration: 0.9, delay: 0, options: .curveEaseOut) {
            self.ringView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.ringView.alpha = 0
        }
    }

    // MARK: - SceneProtocol

    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
    }

    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            gesture.scale = 1.0
        }
    }

    func play() {
        gameState.CurrentState = .initializing
        timer.start()
        elapsedTime = 3.0
        lastShown = -1
    }

    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        if gameState.CurrentState != .initializing {
            return
        }
        if elapsedTime <= 0 {
            // request scene change
            timer.stop()
            requestScene(nextScene)
            return
        }

        let number = max(1, Int(ceil(elapsedTime)))
        if number != lastShown {
            lastShown = number
            showNumber(number)
        }

        elapsedTime -= Double(timer.getTickSeconds())
    }
}
