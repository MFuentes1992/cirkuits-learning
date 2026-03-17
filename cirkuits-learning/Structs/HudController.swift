//
//  HudController.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/11/25.
//
import SwiftUI


class HudController {
    private var timerLabel: UILabel!
    private var scoreLabel: UILabel!
    private var countDownLabel: UILabel!
    private var pauseButton: UIButton!
    private var playButton: UIButton!
    private var parentView: UIView
    private var comboGauge: ComboGauge!
    private var gameState: GameState!
    private var speechRecognition: SpeechRecognizer
    private var timer: TimeController!
    private var countDown: TimeInterval = 0
    private var remainingTime: TimeInterval = 0
    private var microphoneStatus: MicrophoneState
    private var microphoneButton: UIButton!
    private var prevComboState: Int = 0
    
    private var lookAndFeel: UILayoutLookAndFeel!
    
    init(parentView: UIView, gameState: GameState) {
        self.parentView = parentView
        self.gameState = gameState
        prevComboState = gameState.Streak
        microphoneStatus = .unmuted
        lookAndFeel = UILayoutLookAndFeel(color: .white, foreColor: .darkGray, buttonSize: 32, fontSize: 32)
        speechRecognition = SpeechRecognizer(gameState: gameState)
        setupHUD()
        updateTimerDisplay()
    }
    
    
    func setupHUD() {
        timerLabel = UILabel()
        timerLabel.font = .monospacedSystemFont(ofSize: lookAndFeel.fontSize, weight: .bold)
        timerLabel.textColor = lookAndFeel.color
        timerLabel.shadowColor = lookAndFeel.foreColor
        timerLabel.shadowOffset = CGSize(width: 2, height: 2)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self.timerLabel)
        
        // Score label
        scoreLabel = UILabel()
        scoreLabel.font = .monospacedSystemFont(ofSize: lookAndFeel.fontSize, weight: .bold)
        scoreLabel.textColor = lookAndFeel.color
        scoreLabel.shadowColor = lookAndFeel.foreColor
        scoreLabel.shadowOffset = CGSize(width: 2, height: 2)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.text = "000"
        parentView.addSubview(self.scoreLabel)
        
        // Countdown label
        countDownLabel = UILabel()
        countDownLabel.font = .monospacedSystemFont(ofSize: 42, weight: .bold)
        countDownLabel.textColor = lookAndFeel.color
        countDownLabel.shadowColor = lookAndFeel.foreColor
        countDownLabel.shadowOffset = CGSize(width: 2, height: 2)
        countDownLabel.translatesAutoresizingMaskIntoConstraints = false
        countDownLabel.text = "\(countDown)"
        countDownLabel.isHidden = true
        parentView.addSubview(countDownLabel)
        
        // Pause Button
        pauseButton = UIButton(type: .system)
        let pauseConfiguration = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        pauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: pauseConfiguration), for: .normal)
        pauseButton.tintColor = lookAndFeel.color
        pauseButton.addTarget(self, action: #selector(togglePause), for: .touchUpInside)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        // pauseButton.isHidden = true
        parentView.addSubview(pauseButton)
        
        // Mute Button
        microphoneButton = UIButton(type: .system)
        let microphoneConfiguration = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        microphoneButton.setImage(UIImage(systemName: "microphone.circle.fill", withConfiguration: microphoneConfiguration), for: .normal)
        microphoneButton.tintColor = lookAndFeel.color
        microphoneButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(microphoneButton)
        
        //Play Button
        playButton = UIButton(type:.system)
        let playConfig = UIImage.SymbolConfiguration(pointSize: lookAndFeel.buttonSize, weight: .regular)
        playButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: playConfig), for: .normal)
        playButton.tintColor = lookAndFeel.color
        playButton.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(playButton)
        
        //combo Gauge
        comboGauge = ComboGauge(frame: CGRect(x: 0, y:0, width: 100, height: 100), maxCombo: gameState.MaxStreak)
        comboGauge.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(comboGauge)
        
        
        
        // Constraints
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20),
            
            scoreLabel.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20),
            
            countDownLabel.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            countDownLabel.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            
            playButton.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            
            
            pauseButton.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            pauseButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: lookAndFeel.buttonSize + 15),
            
            microphoneButton.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            microphoneButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: lookAndFeel.buttonSize + 15),
            
            comboGauge.widthAnchor.constraint(equalToConstant: 120),
            comboGauge.heightAnchor.constraint(equalToConstant: 140),
            comboGauge.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 5),
            comboGauge.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -10)
            
        ])
    }
    
    @objc func toggleMute() {
        var iconName = "microphone.slash.circle.fill"
        if microphoneStatus == .unmuted {
            microphoneStatus = .muted
            speechRecognition.stopTranscribing()
        } else {
            microphoneStatus = .unmuted
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
    
    @objc func startGame() {
        playButton.isHidden = true
        countDownLabel.isHidden = false
        parentView.setNeedsDisplay()
        gameState.CurrentState = .initializing
        gameState.Timer.start()
        Task {
            do {
                try speechRecognition.startRecording()
            } catch {
                print("Cannot start recording...")
            }
        }
    }
    
    func updateTimerDisplay() {
        if gameState.CurrentState != .running { return }
        remainingTime -= Double(gameState.Timer.getTickSeconds())
        let minutes = Int(remainingTime / 60)
        let seconds = Int(remainingTime) % 60
        let formattedTimerString = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.text = formattedTimerString
    }
    
    func updateScoreDisplay() {
        let formattedString = String(format: "%03d", gameState.Score)
        scoreLabel.text = formattedString
    }
    
    func updateCountDown() {
        if gameState.CurrentState != .initializing { return }
        if countDown != 0 {
            countDown -= Double(gameState.Timer.getTickSeconds())
            if countDown == 0 { return }
            let formattedScoreString = String(format: "%.0f", countDown)
            countDownLabel.text = formattedScoreString
        } else {
            countDownLabel.text = ""
            countDownLabel.isHidden = true
            countDownLabel.removeFromSuperview()
            countDown = 0
            gameState.CountDown = 0
            UIView.animate(
                withDuration: 1,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    self.pauseButton.transform = CGAffineTransform(translationX: -self.lookAndFeel.buttonSize - 20, y: 0)
                    self.microphoneButton.transform = CGAffineTransform(translationX: -self.lookAndFeel.buttonSize - 70, y: 0)
                    
            })
            
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseInOut],
                animations: {
                    self.comboGauge.transform = CGAffineTransform(scaleX: 1.05, y: 1.05);
                })
                    
            gameState.CurrentState = .running
        }
    }
    
    func updateHud() {
        if gameState.ConfigLoaded && gameState.CurrentState == .stop {
            // TODO: We can display loading spinner
            countDown =  gameState.CountDown
            remainingTime = gameState.LevelDuration
        } else {
            updateTimerDisplay()
            updateScoreDisplay()
            updateCountDown()
            if prevComboState != gameState.Streak {
                prevComboState = gameState.Streak
                comboGauge.incrementCombo(value: gameState.Streak)
            }
        }
    }
}



