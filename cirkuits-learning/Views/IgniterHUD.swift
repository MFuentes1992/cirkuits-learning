//
//  IgniterHUD.swift
//  cirkuits-learning
//
//  Reworked to match the Igniter target design:
//   • top pink progress-dot row
//   • bottom-left streak funnel (with red score circle + xNN badge)
//   • pink circular mic / pause buttons, bottom-right
//   • layered teal "Nice!" checkmark on a correct answer
//   • animated pixel fire border tied to the streak ("ignition")
//
import Foundation
import SwiftUI
import os

class IgniterHUD {
    private let logger = Logger(subsystem: "com.cirkuits.igniter", category: "IgniterHUD")

    // Legacy labels kept for compatibility; hidden in the new design.
    private var timerLabel: UILabel
    private var scoreLabel: UILabel

    // New HUD elements
    private let progressDots: ProgressDotsView
    private let comboGauge: ComboGauge
    private let niceOverlay: NiceCheckmarkView
    private let fireBorder: FireBorderView
    private var pauseButton: UIButton
    private var microphoneButton: UIButton

    private var parentView: UIView
    private var microphoneState: MicrophoneState
    private weak var speechRecognition: SpeechRecognizer?
    private var gameState: GameState
    private var levelRemainingTime: TimeInterval

    private let buttonDiameter: CGFloat = 56

    init(parentView: UIView, gameState: GameState, speechRecognizer: SpeechRecognizer? = nil) {
        self.gameState = gameState
        self.parentView = parentView
        self.timerLabel = UILabel()
        self.scoreLabel = UILabel()
        self.progressDots = ProgressDotsView(total: 8)
        self.comboGauge = ComboGauge(frame: CGRect(x: 0, y: 0, width: 220, height: 210),
                                     maxCombo: MaxStreak)
        self.niceOverlay = NiceCheckmarkView()
        self.fireBorder = FireBorderView()
        self.microphoneButton = UIButton(type: .custom)
        self.pauseButton = UIButton(type: .custom)
        self.levelRemainingTime = gameState.LevelDuration
        self.speechRecognition = speechRecognizer
        self.microphoneState = .unmuted
        setUpHUD()
    }

    // MARK: Setup
    private func makeCircleButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = IgniterPalette.pink
        button.layer.cornerRadius = buttonDiameter / 2
        button.tintColor = IgniterPalette.cream
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    func setUpHUD() {
        // Legacy labels: kept updating but not shown (design has no on-screen timer/score text).
        timerLabel.isHidden = true
        scoreLabel.isHidden = true
        timerLabel.text = "00:00"
        scoreLabel.text = "000"

        // Fire border (added first -> sits behind the HUD chrome, above the letters).
        fireBorder.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(fireBorder)

        // Progress dots
        progressDots.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(progressDots)

        // Streak funnel gauge
        comboGauge.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(comboGauge)

        // Circular buttons
        microphoneButton = makeCircleButton(icon: "mic.fill", action: #selector(toggleMute))
        pauseButton = makeCircleButton(icon: "pause.fill", action: #selector(togglePause))
        parentView.addSubview(microphoneButton)
        parentView.addSubview(pauseButton)

        // "Nice!" overlay (top-most)
        niceOverlay.translatesAutoresizingMaskIntoConstraints = false
        niceOverlay.alpha = 0
        parentView.addSubview(niceOverlay)

        let guide = parentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Fire spans the full width along the bottom.
            fireBorder.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            fireBorder.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            fireBorder.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            fireBorder.heightAnchor.constraint(equalToConstant: 340),

            // Progress dots across the top.
            progressDots.topAnchor.constraint(equalTo: guide.topAnchor, constant: 14),
            progressDots.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 28),
            progressDots.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -28),
            progressDots.heightAnchor.constraint(equalToConstant: 16),

            // Streak funnel, bottom-left.
            comboGauge.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 10),
            comboGauge.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -6),
            comboGauge.widthAnchor.constraint(equalToConstant: 220),
            comboGauge.heightAnchor.constraint(equalToConstant: 210),

            // Buttons, bottom-right.
            pauseButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20),
            pauseButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -18),
            pauseButton.widthAnchor.constraint(equalToConstant: buttonDiameter),
            pauseButton.heightAnchor.constraint(equalToConstant: buttonDiameter),

            microphoneButton.trailingAnchor.constraint(equalTo: pauseButton.leadingAnchor, constant: -16),
            microphoneButton.centerYAnchor.constraint(equalTo: pauseButton.centerYAnchor),
            microphoneButton.widthAnchor.constraint(equalToConstant: buttonDiameter),
            microphoneButton.heightAnchor.constraint(equalToConstant: buttonDiameter),

            // "Nice!" overlay, upper-centre.
            niceOverlay.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            niceOverlay.topAnchor.constraint(equalTo: guide.topAnchor, constant: 100),
            niceOverlay.widthAnchor.constraint(equalToConstant: 100),
            niceOverlay.heightAnchor.constraint(equalToConstant: 100),
        ])

        fireBorder.start()
    }

    // MARK: Controls
    @objc func toggleMute() {
        guard let speechRecognition = speechRecognition else { return }
        var iconName = "mic.slash.fill"
        if microphoneState == .unmuted {
            microphoneState = .muted
            Task { @MainActor in speechRecognition.stop() }
        } else {
            microphoneState = .unmuted
            iconName = "mic.fill"
            Task { @MainActor in
                do { try await speechRecognition.startRecording() }
                catch { print("Cannot start recording: \(error.localizedDescription)") }
            }
        }
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        microphoneButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
    }

    @objc func togglePause() {
        var state = gameState.CurrentState
        var iconName = "pause.fill"
        if state == .running {
            state = .pause
            iconName = "play.fill"
            gameState.Timer.pause()
            Task { @MainActor in speechRecognition?.pause() }
        } else if state == .pause {
            state = .running
            gameState.Timer.resume()
            Task { @MainActor in
                do { try speechRecognition?.resume() }
                catch { logger.error("Failed to resume speech recognition: \(error.localizedDescription)") }
            }
        }
        gameState.CurrentState = state
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        pauseButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
    }

    // MARK: Updates
    func updateTimerDisplay(gameElapsedTime: Double) {
        levelRemainingTime = gameState.LevelDuration - gameElapsedTime
        let minutes = Int(levelRemainingTime / 60)
        let seconds = Int(levelRemainingTime) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    func updateHudScore(score: Int) {
        scoreLabel.text = String(format: "%03d", gameState.Score)
        comboGauge.updateScore(gameState.Score)
    }

    /// Update the top progress row. `filled` completed of `total` prompts.
    func updateProgress(filled: Int, total: Int) {
        progressDots.setTotal(total)
        progressDots.setProgress(filled: filled)
    }

    //TODO: Rename this to incrementStreak
    func incrementCombo(_ value: Int) {
        comboGauge.incrementCombo(value: value)
        fireBorder.setStreak(value, maxStreak: gameState.MaxStreak)
    }

    func showCorrectFeedback() {
        niceOverlay.play()
    }
}
