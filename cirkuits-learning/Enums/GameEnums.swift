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
        case .external: return "headphones"
        }
    }

    /// Short player-facing label for the active input.
    var displayName: String {
        switch self {
        case .builtIn: return "Built-in Mic"
        case .external: return "Headset"
        }
    }
}

enum GameScenes {
    case Menu
    case CountDown
    case Igniter
    case GameOver
}

enum PlayerState {
    case Speaking
    case Idle
}

let MaxStreak = 3
