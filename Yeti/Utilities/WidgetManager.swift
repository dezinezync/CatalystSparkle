//
//  WidgetManager.swift
//  Elytra
//
//  Created by Nikhil Nigade on 20/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import Foundation
import WidgetKit

@objc public class WidgetManager: NSObject {
    
    @objc public static func reloadAllTimelines() {
        
        WidgetCenter.shared.reloadAllTimelines();
        
    } 

    @objc public static func reloadTimeline(name: String) {
        
        WidgetCenter.shared.reloadTimelines(ofKind: name)
        
    }
    
}
