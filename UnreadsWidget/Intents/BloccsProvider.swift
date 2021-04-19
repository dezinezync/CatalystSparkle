//
//  BloccsProvider.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import SDWebImage
import WidgetKit
import Models

struct BloccsProvider: IntentTimelineProvider {
   
    func loadData (name: String, configuration: BloccsIntent) -> UnreadEntries? {
        
        var json: UnreadEntries
        
        if let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra") {
                
            let fileURL = baseURL.appendingPathComponent(name)
                
            if let data = try? Data(contentsOf: fileURL) {
                // we're OK to parse!
                do {
                    
                    let decoder = JSONDecoder();
                    
                    let entries: [WidgetArticle] = try decoder.decode([WidgetArticle].self, from: data)
                    
                    let showFavicons: Bool = configuration.showFavicons?.boolValue ?? true
                    
                    for index in 0..<entries.count {
                        
                        if showFavicons == false {
                                
                            entries[index].showFavicon = false
                            
                        }
                        
                        entries[index].showCover = true
                        
                    }
                    
                    json = UnreadEntries(date: Date(), entries: entries)
                    
                    return json
                }
                catch {
                    print(error.localizedDescription)
                }
                
            }
            
        }
        
        return nil
        
    }
    
    public func getSnapshot(for configuration: BloccsIntent, in context: Context, completion: @escaping (UnreadEntries) -> Void) {
    
        if let jsonData: UnreadEntries = loadData(name: "bloccs.json", configuration: configuration) {
            
            if (configuration.showFavicons?.boolValue == false) {
                    
                for item in jsonData.entries {
                    
                    if (item.favicon != nil) {
                        item.favicon = nil
                    }
                    
                }
                
            }
            
            loadImagesDataFromPackage(package: jsonData) {
                
                completion(jsonData)
                
            }
            
        }
        
    }
    
    public func getTimeline(for configuration: BloccsIntent, in context: Context, completion: @escaping (Timeline<UnreadEntries>) -> Void) {
        
        if let jsonData = loadData(name: "bloccs.json", configuration: configuration) {
        
            var entries: [UnreadEntries] = []
            
            entries.append(jsonData)
            
            loadImagesDataFromPackage(package: jsonData) {
                
                let timeline = Timeline(entries: entries, policy: .never)
                
                completion(timeline)
                
            }
            
        }

    }
    
    func placeholder(in context: Context) -> UnreadEntries {
        
        if let jsonData = loadData(name: "bloccs.json", configuration: BloccsIntent()) {
            
            return jsonData;
            
        }
        
        let entryCol = UnreadEntries(date: Date(), entries: []);
        
        return entryCol
        
    }
    
}
