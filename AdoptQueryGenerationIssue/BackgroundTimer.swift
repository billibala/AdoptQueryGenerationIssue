//
//  BackgroundTimer.swift
//  AdoptQueryGenerationIssue
//
//  Created by Bill on 5/25/17.
//  Copyright © 2017 Headnix. All rights reserved.
//

import Foundation

protocol BackgroundTimerEventHandling: class {
    func timerHandler()
}

class BackgroundTimer {
    var timerQueue: DispatchQueue {
        return DispatchQueue.global(qos: .default)
    }

    private lazy var timerSource: DispatchSourceTimer = {
        return DispatchSource.makeTimerSource(flags: [], queue: self.timerQueue)
    }()

    weak var handler: BackgroundTimerEventHandling? = nil

    func start() {
        timerSource.setEventHandler { [weak self] in
            if let strongSelf = self {
                strongSelf.handleTimer()
            }
        }
        timerSource.scheduleRepeating(deadline: DispatchTime.now() + 2.0, interval: 0.5)
        timerSource.activate()
    }

    private func handleTimer() {
        if let handler = handler {
            handler.timerHandler()
        }
    }

    func stop() {
        timerSource.cancel()
    }
}
