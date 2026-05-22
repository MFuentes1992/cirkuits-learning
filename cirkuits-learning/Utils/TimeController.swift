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
    var StartTime: Double {
        get { return startTime }
        set { startTime = newValue }
    }
    private var currentTime: Double
    private var isStopped: Bool
    private var isPaused: Bool = false
    private var pauseStart: Double = 0   // -- Wall time when the current pause began
    private var pausedAccum: Double = 0  // -- Total time spent paused, excluded from elapsed

    init() {
        self.isStopped = true
        self.currentTime = 0
    }

    func start() {
        startTime = Date().timeIntervalSince1970
        currentTime = startTime
        isStopped = false
        isPaused = false
        pauseStart = 0
        pausedAccum = 0
    }

    func stop() {
        isStopped = true
    }

    /// Freezes elapsed time without stopping the timer.
    func pause() {
        guard !isPaused else { return }
        isPaused = true
        pauseStart = Date().timeIntervalSince1970
    }

    /// Resumes from a pause, discounting the paused interval from elapsed time.
    func resume() {
        guard isPaused else { return }
        isPaused = false
        pausedAccum += Date().timeIntervalSince1970 - pauseStart
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
    
    func getTimeMilliseconds() -> Double {
        return getElapsedTime() * 1000
    }

    func getElapsedTime() -> Double {
        // -- While paused, freeze at the moment the pause started.
        let now = isPaused ? pauseStart : Date().timeIntervalSince1970
        return now - startTime - pausedAccum
    }
   
    func isComplete() -> Bool {
        return isStopped
    }
}
