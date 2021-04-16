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
    
    static var usingUnreadsWidget: Bool = false
    
    public static func updateState() {
        
        // set all to false.
        usingUnreadsWidget = false
        
        WidgetCenter.shared.getCurrentConfigurations { result in
            
            switch result {
            case .failure(let error):
                print(error)
                
            case .success(let configs):
                for config in configs {
                    // update if the config comes in. 
                    if (config.kind == "UnreadsWidget") {
                        usingUnreadsWidget = true
                    }
                }
            }
            
        }
        
    }
    
    public static func reloadAllTimelines() {
        
        WidgetCenter.shared.reloadAllTimelines();
        
    } 

    public static func reloadTimeline(name: String) {
        
        WidgetCenter.shared.reloadTimelines(ofKind: name)
        
        print("Reloaded \(name) widget")
        
    }
    
}
