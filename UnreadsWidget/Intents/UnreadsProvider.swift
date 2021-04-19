//
//  UnreadsProvider.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import SDWebImage
import WidgetKit
import Models

struct UnreadsProvider: IntentTimelineProvider {
   
    func loadData (name: String, configuration: UnreadsIntent) -> UnreadEntries? {
        
        var json: UnreadEntries
        
        if let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra") {
                
            let fileURL = baseURL.appendingPathComponent(name)
                
            if let data = try? Data(contentsOf: fileURL) {
                // we're OK to parse!
                do {
                    
                    let decoder = JSONDecoder();
                    
                    let entries: [WidgetArticle] = try decoder.decode([WidgetArticle].self, from: data)
                    
                    let showFavicons: Bool = configuration.showFavicons?.boolValue ?? true
                    let showCovers: Bool = configuration.showCovers?.boolValue ?? true
                    
                    for index in 0..<entries.count {
                        
                        if showFavicons == false {
                                
                            entries[index].showFavicon = false
                            
                        }
                        
                        if showCovers == false {
                                
                            entries[index].showCover = false
                            
                        }
                        
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
    
    public func getSnapshot(for configuration: UnreadsIntent, in context: Context, completion: @escaping (UnreadEntries) -> Void) {
    
        if let jsonData: UnreadEntries = loadData(name: "articles.json", configuration: configuration) {
            
            if (configuration.showFavicons?.boolValue == false) {
                    
                for item in jsonData.entries {
                    
                    if (item.favicon != nil) {
                        item.favicon = nil
                    }
                    
                }
                
            }
            
            if (configuration.showCovers?.boolValue == false) {
                    
                for item in jsonData.entries {
                    
                    if (item.coverImage != nil) {
                        item.coverImage = nil
                    }
                    
                }
                
            }
            
            loadImagesDataFromPackage(package: jsonData) {
                
                completion(jsonData)
                
            }
            
        }
        
    }
    
    public func getTimeline(for configuration: UnreadsIntent, in context: Context, completion: @escaping (Timeline<UnreadEntries>) -> Void) {
        
        if let jsonData = loadData(name: "articles.json", configuration: configuration) {
        
            var entries: [UnreadEntries] = []
            
            entries.append(jsonData)
            
            loadImagesDataFromPackage(package: jsonData) {
                
                let timeline = Timeline(entries: entries, policy: .never)
                
                completion(timeline)
                
            }
            
        }

    }
    
    func placeholder(in context: Context) -> UnreadEntries {
        
        if let jsonData = loadSampleData(name: "articles.json", configuration: UnreadsIntent()) {
        
            return jsonData;
            
        }
        
        let entryCol = UnreadEntries(date: Date(), entries: []);
        
        return entryCol
        
    }
    
}
