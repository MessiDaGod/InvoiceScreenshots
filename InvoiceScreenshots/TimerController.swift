//
//  TimerController.swift
//  InvoiceScreenshots
//
//  Created by Joe Shakely on 9/12/23.
//

import Foundation
import AppKit

class TimerController {
    var counter = 600
    var timer: Timer?
    var updateLabel: ((String) -> Void)?
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        stopTimer()
        counter = 600
        let timeString = String(format: "%02d:%02d", counter / 60, counter % 60)
        updateLabel?(timeString)
    }

    @objc private func updateCounter() {
        if counter > 0 {
            counter -= 1
            let minutes = counter / 60
            let seconds = counter % 60
            let timeString = String(format: "%02d:%02d", minutes, seconds)
            updateLabel?(timeString)
        } else {
            counter = 600
        }
    }
}
