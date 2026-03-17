//
//  TimeController.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 28/10/25.
//
import Foundation
class TimeController {
    private var tick: Double = 0
    private var startTime: Double = 0 // -- Start time in seconds
    private var currentTime: Double
    private var isStopped: Bool
    
    init() {
        self.isStopped = true
        self.currentTime = 0
    }
        
    func start() {
        startTime = Date().timeIntervalSince1970
        currentTime = startTime
        isStopped = false
    }
    
    func stop() {
        isStopped = true        
    }
    
    func update() {
        if(isStopped) {
            return;
        }
        tick = Date().timeIntervalSince1970 - currentTime
        if tick >= 1 {
            currentTime = Date().timeIntervalSince1970
        }
    }
    
    func getTickSeconds() -> Int {
        return Int(tick)
    }
    
    func getElapsedTime() -> Double {
        return Date().timeIntervalSince1970 - startTime
    }
    
    func isComplete() -> Bool {
        return isStopped
    }
}
