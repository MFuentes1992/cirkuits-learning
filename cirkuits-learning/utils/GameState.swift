//
//  GameState.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 03/11/25.
//
class GameState {
    private var combo: Int = 0
    private var gaugeController: ComboGauge!
    
    
    func incrementCombo() {
        if combo < 4 {
            combo += 1
            if gaugeController != nil {
                gaugeController.setCombo(combo)
            }            
        }
    }
    
    func getComboCounter() -> Int {
        return self.combo
    }
    
    func resetCombo() {
        combo = 0
    }
    
    func setGaugeController(gauge: ComboGauge) {
        self.gaugeController = gauge
    }
}
