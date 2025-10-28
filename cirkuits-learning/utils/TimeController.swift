//
//  TimeController.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 28/10/25.
//
import Foundation
class TimeController {
    private var tick: Float = 0.0
    private var ellapsedTime: Float = 0.0
    private var startTime: Float = 0.0 // -- Start time in seconds
    private var countDown: Bool
    private var isStopped: Bool
    private var loop: Bool
    
    init(startTime:Float, countDown: Bool = false, loop: Bool = false) {
        self.startTime = startTime
        self.countDown = countDown
        self.loop = loop
        self.isStopped = true
    }
    
    init(tick: Float, ellapsedTime: Float, startTime: Float, countDown: Bool = false, loop: Bool = false) {
        self.tick = tick
        self.ellapsedTime = ellapsedTime
        self.startTime = startTime
        self.countDown = countDown
        self.loop = loop
        self.isStopped = true
    }
    
    func start() {
        ellapsedTime = startTime
        isStopped = false
    }
    
    func stop() {
        isStopped = true
    }
    
    func update() {
        if(isStopped) {
            return;
        }
        tick += 1.0 / 60.0
        if(tick >= 1 && countDown) {
            ellapsedTime -= tick - tick.truncatingRemainder(dividingBy: 1)
            let delta = tick.truncatingRemainder(dividingBy: 1)
            tick = delta
        }
        if(!countDown) {
            ellapsedTime = Float(Date().timeIntervalSince1970) - startTime
        }
        if(ellapsedTime <= 0 && countDown && !loop) {
            stop()
        }
        
        if(ellapsedTime <= 0 && countDown && loop) {
            stop()
            start()
        }
    }
    
    func getEllapsedTime() -> Float {
        return ellapsedTime
    }
}
