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
import Intents

@objcMembers public class WidgetManager: NSObject {
    
    static var usingUnreadsWidget: Bool = false
    static var usingBloccsWidget: Bool = false
    
    static var usingFoldersWidget: Bool = false
    static var selectedFolder: WidgetFolder? {
        
        didSet {
            
            MyAppDelegate.coordinator.updateSharedFoldersData()
            
            if selectedFolder != oldValue, let _ = selectedFolder {
                MyAppDelegate.coordinator.updateSharedFoldersArticles()
            }
            
        }
        
    }
    
    public static func updateState() {
        
        // set all to false.
        usingUnreadsWidget = false
        usingBloccsWidget = false
        usingFoldersWidget = false
        
        WidgetCenter.shared.getCurrentConfigurations { result in
            
            switch result {
            case .failure(let error):
                print(error)
                
            case .success(let configs):
                
                for config in configs {
                    // update if the config comes in. 
                    if (config.kind == "Unreads Widget") {
                        usingUnreadsWidget = true
                    }
                    else if (config.kind == "Bloccs Widget") {
                        usingBloccsWidget = true
                    }
                    else if (config.kind == "Folders Widget") {
                        usingFoldersWidget = true
                        
                        if let foldersIntent: INIntent = config.configuration,
                           let folder = foldersIntent.value(forKey: "folders") as? INObject,
                           let identifer = folder.identifier as NSString? {
                            
                            let displayString = folder.displayString
                            
                            let widgetFolder = WidgetFolder(title: displayString, folderID: UInt(identifer.integerValue))
                            
                            self.selectedFolder = widgetFolder
                            
                        }
                        
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
