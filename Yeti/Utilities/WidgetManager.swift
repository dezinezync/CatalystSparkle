//
//  WidgetManager.swift
//  Elytra
//
//  Created by Nikhil Nigade on 20/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import Foundation
import WidgetKit
import Models
import Networking
import DBManager
import BackgroundTasks

@objcMembers public class WidgetManager: NSObject {
    
    public static func reloadAllTimelines() {
        
        WidgetCenter.shared.reloadAllTimelines();
        
    } 

    public static func reloadTimeline(name: String) {
        
        WidgetCenter.shared.reloadTimelines(ofKind: name)
        
        print("Reloaded \(name) widget")
        
    }
    
}
