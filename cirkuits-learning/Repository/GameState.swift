//
//  GameState.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 03/11/25.
//
import SwiftUI
class GameState {
    private var combo: Int
    private var score: Int
    private var streak: StreakChain
    // -- TODO: move to configuration file - persistance
    private var lives = 99
    private var scoreLimit = 999
    private var highScore = 0
    private var maxCombo = 4 // max combo bars
    private var remainingTime: TimeInterval = 99 // Total level
    private var timer: TimeController!
    
    private var currentState: PlayState
    private var countDown: TimeInterval = TimeInterval(Initializers.initCountDown)
    private var capturedAnswer: String = ""
    private var answerOffset = 0
    var CapturedAnswer: String {
        get { capturedAnswer }
        set {capturedAnswer = newValue.components(separatedBy: .whitespaces).last ?? "" }
    }
    var RemainingTime: TimeInterval {
        get { remainingTime }
        set { remainingTime =  newValue }
    }
    var Score: Int {
        get { score }
        set { score = newValue }
    }
    var HighScore: Int {
        get { return highScore }
        set { highScore = max(highScore, newValue) }
    }
    var Streak: StreakChain {
        get { streak }
        set { streak = newValue }
    }
    var CurrentState: PlayState {
        get { currentState }
        set { currentState = newValue }
    }
    var CountDown: TimeInterval {
        get { countDown }
    }
    var Timer: TimeController {
        get { return timer }
        set { timer =  newValue }
    }
    var Combo:Int {
        get { return combo }
        set { combo = newValue }
    }
    
    init(gameState: PlayState) {
        self.currentState = gameState
        self.combo = 0
        self.score = 0
        self.streak = .oneX
    }
}
