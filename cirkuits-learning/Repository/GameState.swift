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
    private var lives: Int!
    private var highScore: Int
    private var levelDuration: TimeInterval!
    private var timer: TimeController // -- We should always pass the current instance of active timer
    private var configLoaded: Bool = false
    
    private var currentState: PlayState
    private var countDown: TimeInterval!
    private var capturedAnswer: String = ""
    private var isAnswering: Bool = false
    private var correctanswer: Bool = false
    private var nextWordFoo: Bool = false
    private var wordTimeToLive: TimeInterval!
    private var wordTimeToAnswer: TimeInterval!
    private var maxStreak: Int = 0
    private var streak: Int = 0
    
    
    var CapturedAnswer: String {
        get { capturedAnswer }
        set {capturedAnswer = newValue.components(separatedBy: .whitespaces).last ?? "" }
    }
    var LevelDuration: TimeInterval {
        get { levelDuration }
        set { levelDuration =  newValue }
    }
    var Score: Int {
        get { score }
        set { score = newValue }
    }
    var Lives: Int {
        get { return lives }
        set { lives = newValue }
    }
    var HighScore: Int {
        get { return highScore }
        set { highScore = max(highScore, newValue) }
    }
    var CurrentState: PlayState {
        get { currentState }
        set { currentState = newValue }
    }
    var CountDown: TimeInterval {
        get { countDown }
        set { countDown =  newValue }
    }
    var Timer: TimeController {
        get { return timer }
        set { timer =  newValue }
    }
    var Combo:Int {
        get { return combo }
        set { combo = newValue }
    }
    var MaxStreak:Int {
        get { return maxStreak }
        set { maxStreak = newValue }
    }
    var Streak:Int {
        get { return streak }
        set { streak = newValue }
    }
    var CorrectAnswer: Bool {
        get { return correctanswer }
        set { correctanswer = newValue }
    }
    var WordTimeToLive: TimeInterval {
        get { return wordTimeToLive }
        set { wordTimeToLive = newValue }
    }
    var WordTimeToAnswer: TimeInterval {
        get { return wordTimeToAnswer }
        set { wordTimeToAnswer = newValue }
    }
    var NextWordFoo: Bool {
        get { return nextWordFoo }
    }
    var IsAnswering: Bool {
        get { return isAnswering }
        set { isAnswering =  newValue }
    }
    var ConfigLoaded: Bool {
        get { return configLoaded }
        set { configLoaded = newValue }
    }
    
    init(gameState: PlayState, timer: TimeController) {
        self.currentState = gameState
        self.timer = timer
        
        self.combo = 0
        self.score = 0
        self.highScore = 0
        self.maxStreak = 3
    }
}
