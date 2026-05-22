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

enum AudioInputType {
    case builtIn
    case external

    /// SF Symbol name representing this input type.
    var iconName: String {
        switch self {
        case .builtIn: return "mic.fill"
        case .external: return "airpods"
        }
    }
}

enum GameScenes {
    case CountDown
    case Igniter
    case GameOver
}

enum PlayerState {
    case Speaking
    case Idle
}

let MaxStreak = 3
