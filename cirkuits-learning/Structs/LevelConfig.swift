//
//  LevelConfig.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 29/10/25.
// -- Time is measured in seconds

struct Initializers {
    static let initCountDown = 3
}

struct LevelConfig {
    var timeWindow: Double
    var levelDuration: Double
    var lives: Int
    var levelCountDown: Int
}
