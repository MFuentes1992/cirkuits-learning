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
    // -- TODO: move to configuration file - persistance
    private var scoreLimit = 999
    private var highScore = 0
    private var maxCombo = 4
    private var reminingTime: TimeInterval = 60
    
    private var gameState: PlayState
    private var countDownTime: TimeInterval = 3
    
    init(gameState: PlayState) {
        self.gameState = gameState
        self.combo = 0
        self.score = 0
    }
    
    
    func incrementCombo() {
        if combo < maxCombo {
            combo += 1
        }
    }
    
    func setScore(score: Int) {
        if score < scoreLimit {
            self.score = score
        }
    }
    
    func setState(state: PlayState) {
        self.gameState = state
    }
    
    func incrementScore(increment: Int) {
        if self.score + increment < scoreLimit {
            self.score += increment
        }
    }

    func setReminingTime(time: TimeInterval) {
        self.reminingTime = time
    }
    
    func decrementTime(time: TimeInterval) {
        self.reminingTime -= time
    }
    
    func decrementCountDown(time: TimeInterval) {
        if countDownTime > 0 {
            countDownTime -= time
        }
    }
    
    func getComboCounter() -> Int {
        return self.combo
    }
    
    func getCurrentScore() -> Int {
        return self.score
    }
    
    func getHighScore() -> Int {
        return max(score, highScore)
    }
        
    func getCurrentState() -> PlayState {
        return self.gameState
    }
    
    func getReminingTime() -> TimeInterval {
        return reminingTime
    }
    
    func getCountDown() -> TimeInterval {
        return countDownTime
    }
    
    func resetCombo() {
        combo = 0
    }
}
