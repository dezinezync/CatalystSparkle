//
//  Utilities.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 19/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit
import Intents
import SDWebImageSwiftUI
import Models

public typealias LoadImagesCompletionBlock = () -> Void

public func loadImagesDataFromPackage (package: UnreadEntries, completion: LoadImagesCompletionBlock? = nil) {
    
    let imageRequestGroup = DispatchGroup()
    
    for entry in package.entries {
        
        if (entry.showFavicon == true && entry.favicon != nil && entry.favicon?.absoluteString != "") {
            
            imageRequestGroup.enter()
            
            SDWebImageManager.shared.loadImage(with: entry.favicon, options: .highPriority, progress: nil) { (image: UIImage?, _: Data?, error: Error?, _: SDImageCacheType, _: Bool, _: URL?) in
                
                imageRequestGroup.leave()
                
            }
            
        }
        
        if (entry.showCover == true && entry.coverImage != nil) {
            
            imageRequestGroup.enter()
            
            SDWebImageManager.shared.loadImage(with: entry.coverImage, options: .highPriority, progress: nil) { (image: UIImage?, _: Data?, error: Error?, _: SDImageCacheType, _: Bool, _: URL?) in
                
                imageRequestGroup.leave()
                
            }
            
        }
        
    }
    
    imageRequestGroup.notify(queue: .main) {
        completion!()
    }
    
}

public func loadSampleData<T:INIntent> (name: String, configuration: T) -> UnreadEntries? {
    
    var json: UnreadEntries
    
    let baseURL = Bundle.main.bundleURL
    
    let fileURL = baseURL.appendingPathComponent(name)
        
    if let data = try? Data(contentsOf: fileURL) {
        // we're OK to parse!
        do {
            
            let decoder = JSONDecoder();
            
            let entries: [WidgetArticle] = try decoder.decode([WidgetArticle].self, from: data)
            
            if let configuration = configuration as? UnreadsIntent {
                checkForConfiguration(entries: entries, configuration: configuration)
            }
            else if let configuration = configuration as? FoldersIntent {
                checkForConfiguration(entries: entries, configuration: configuration)
            }
            else if let configuration = configuration as? BloccsIntent {
                checkForConfiguration(entries: entries, configuration: configuration)
            }
            
            json = UnreadEntries(date: Date(), entries: entries)
            
            return json
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    return nil
    
}

fileprivate func checkForConfiguration(entries: [WidgetArticle], configuration: UnreadsIntent) {
    
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
    
}

fileprivate func checkForConfiguration(entries: [WidgetArticle], configuration: FoldersIntent) {
    
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
    
}

fileprivate func checkForConfiguration(entries: [WidgetArticle], configuration: BloccsIntent) {
    
    let showFavicons: Bool = configuration.showFavicons?.boolValue ?? true
    
    for index in 0..<entries.count {
        
        if showFavicons == false {
                
            entries[index].showFavicon = false
            
        }
        
        entries[index].showCover = true
        
    }
    
}


