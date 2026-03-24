//
//  GameEnums.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/11/25.
//
enum PlayState {
    case stop
    case pause
    case running
    case initializing
}

enum MicrophoneState {
    case muted
    case unmuted
}

enum GameScenes {
    case CountDown
    case Igniter
    case GameOver
}


let MaxStreak = 3
