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
    private var scoreLimit = 999
    private var highScore = 0
    private var maxCombo = 4 // max combo bars
    private var remainingTime: TimeInterval = 99 // Total level
    
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
    
    init(gameState: PlayState) {
        self.currentState = gameState
        self.combo = 0
        self.score = 0
        self.streak = .oneX
    }
    
    
    func incrementCombo() {
        if combo < maxCombo {
            combo += 1
        }
    }
    
    func incrementScore(increment: Int) {
        if self.score + increment < scoreLimit {
            self.score += increment
        }
    }
    
    func decrementTime(time: TimeInterval) {
        if remainingTime > 0 {
            self.remainingTime -= time
        }
    }
    
    func decrementCountDown(time: TimeInterval) {
        if countDown > 0 {
            countDown -= time
        }
    }
    
    func getHighScore() -> Int {
        return max(score, highScore)
    }
    
    func resetCombo() {
        combo = 0
    }
}
