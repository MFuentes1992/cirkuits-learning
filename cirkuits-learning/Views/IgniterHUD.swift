//
//  IgniterHUD.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 22/03/26.
//

import Foundation
import SwiftUI

class IgniterHUD {
    private var timerLabel: UILabel
    private var scoreLabel: UILabel
    private var pauseButton: UIButton
    private var microphoneButton: UIButton
    private var parentView: UIView
    private var microphoneState: MicrophoneState
    private var speechRecognition: SpeechRecognizer
    private var comboGauge: ComboGauge
    private var lookAndFeel: UILayoutLookAndFeel
    private var gameState: GameState
    private var levelRemainingTime: TimeInterval

    init(parentView: UIView, gameState: GameState) {
        self.gameState = gameState
        self.parentView = parentView
        self.timerLabel = UILabel()
        self.scoreLabel = UILabel()
        self.microphoneButton = UIButton(type: .system)
        self.pauseButton = UIButton(type: .system)
        self.levelRemainingTime = gameState.LevelDuration
        self.comboGauge = ComboGauge(frame: CGRect(x: 0, y:0, width: 100, height: 100), maxCombo: MaxStreak)
        lookAndFeel = UILayoutLookAndFeel(color: .white, foreColor: .darkGray, buttonSize: 32, fontSize: 32)
        speechRecognition = SpeechRecognizer(gameState: gameState)
        microphoneState = .unmuted
        setUpHUD()
    }
    
    func setUpHUD() {
        timerLabel.font = .monospacedSystemFont(ofSize: lookAndFeel.fontSize, weight: .bold)
        timerLabel.textColor = lookAndFeel.color
        timerLabel.shadowColor = lookAndFeel.foreColor
        timerLabel.shadowOffset = CGSize(width: 2, height: 2)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(timerLabel)
        
        // Score label
        scoreLabel.font = .monospacedSystemFont(ofSize: lookAndFeel.fontSize, weight: .bold)
        scoreLabel.textColor = lookAndFeel.color
        scoreLabel.shadowColor = lookAndFeel.foreColor
        scoreLabel.shadowOffset = CGSize(width: 2, height: 2)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.text = "000"
        parentView.addSubview(scoreLabel)
       
        // Pause Button
        let pauseConfiguration = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        pauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: pauseConfiguration), for: .normal)
        pauseButton.tintColor = lookAndFeel.color
        pauseButton.addTarget(self, action: #selector(togglePause), for: .touchUpInside)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(pauseButton)
        
        // Mute Button
        let microphoneConfiguration = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        microphoneButton.setImage(UIImage(systemName: "microphone.circle.fill", withConfiguration: microphoneConfiguration), for: .normal)
        microphoneButton.tintColor = lookAndFeel.color
        microphoneButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(microphoneButton)

        //combo Gauge
        comboGauge.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(comboGauge)


        // Constraints
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20),
            
            scoreLabel.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20),
            
            pauseButton.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            pauseButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: lookAndFeel.buttonSize + 15),
            
            microphoneButton.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            microphoneButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: lookAndFeel.buttonSize + 15),
            
            comboGauge.widthAnchor.constraint(equalToConstant: 120),
            comboGauge.heightAnchor.constraint(equalToConstant: 140),
            comboGauge.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 5),
            comboGauge.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        UIView.animate(
                withDuration: 1,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    self.pauseButton.transform = CGAffineTransform(translationX: -self.lookAndFeel.buttonSize - 20, y: 0)
                    self.microphoneButton.transform = CGAffineTransform(translationX: -self.lookAndFeel.buttonSize - 70, y: 0)
                    
            })
    }
    
    @objc func toggleMute() {
        var iconName = "microphone.slash.circle.fill"
        if microphoneState == .unmuted {
            microphoneState = .muted
            speechRecognition.stopTranscribing()
        } else {
            microphoneState = .unmuted
            iconName = "microphone.circle.fill"
            do {
                try speechRecognition.startRecording()
            } catch {
                print("Cannot start recording...")
            }
        }
        let config = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        microphoneButton.setImage(image, for: .normal)
    }
    
    @objc func togglePause() {
        var state = gameState.CurrentState
        var iconName = "pause.circle.fill"
        if state == .running {
            state = .pause
            iconName = "play.circle.fill"
        } else if state == .pause {
            state = .running
        }
        gameState.CurrentState = state
        let config = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        pauseButton.setImage(image, for: .normal)
    }
    
    func updateTimerDisplay() {
        levelRemainingTime -= Double(gameState.Timer.getTickSeconds())
        let minutes = Int(levelRemainingTime / 60)
        let seconds = Int(levelRemainingTime) % 60
        let formattedTimerString = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.text = formattedTimerString
    }
}
