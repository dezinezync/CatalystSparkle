//
//  FoldersProvider.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import WidgetKit
import SwiftUI
import Models

public struct FoldersCollection: TimelineEntry {
    public let mainItem: WidgetArticle
    public let otherItems: [WidgetArticle]
    public let date: Date = Date()
}

struct FoldersProvider: IntentTimelineProvider {
    
    func loadData (name: String, configuration: FoldersIntent) -> (FoldersCollection?, UnreadEntries?) {
        
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
                    
                    let mainItem: WidgetArticle = json.entries.first(where: { $0.coverImage != nil })!
                    let otherItems: [WidgetArticle] = json.entries.filter { $0.identifier != mainItem.identifier }
                    
                    let collection = FoldersCollection(mainItem: mainItem, otherItems: otherItems)
                    
                    return (collection, json)
                }
                catch {
                    print(error.localizedDescription)
                }
                
            }
            
        }
        
        return (nil, nil)
        
    }
 
    public func getSnapshot(for configuration: FoldersIntent, in context: Context, completion: @escaping (FoldersCollection) -> Void) {
    
        let (collection, jsonData) = loadData(name: "foldersW.json", configuration: configuration)
        
        if let collection = collection, let jsonData = jsonData {
            
            loadImagesDataFromPackage(package: jsonData) {
                
                completion(collection)
                
            }
            
        }
        
    }
    
    public func getTimeline(for configuration: FoldersIntent, in context: Context, completion: @escaping (Timeline<FoldersCollection>) -> Void) {
        
        let (collection, jsonData) = loadData(name: "foldersW.json", configuration: configuration)
        
        if let collection = collection, let jsonData = jsonData {
            
            loadImagesDataFromPackage(package: jsonData) {
                
                let timeline = Timeline(entries: [collection], policy: .never)
                
                completion(timeline)
                
            }
            
        }

    }
    
    func placeholder(in context: Context) -> FoldersCollection {
        
        if let collection = loadSampleFoldersData() {
            
            return collection;
            
        }
        
        let entryCol = FoldersCollection(mainItem: previewData.entries[0], otherItems: Array(previewData.entries[1...3]));
        
        return entryCol
        
    }
    
}
