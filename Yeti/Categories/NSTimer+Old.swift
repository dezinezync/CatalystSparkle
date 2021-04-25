//
//  NSTimer+Old.swift
//  Elytra
//
//  Created by Nikhil Nigade on 25/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation

extension Timer {
    
    func fireOldTimer() {
        
        guard isValid == true else {
            return
        }
        
        if fireDate < Date() {
            fire()
        }
    }
    
}
