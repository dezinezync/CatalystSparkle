//
//  IntentHandler.swift
//  SelectFolderIntents
//
//  Created by Nikhil Nigade on 18/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Intents

struct WidgetFolderHolder: Decodable {
    
    let identifier: String
    let displayString: String
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case displayString
    }
        
}

class IntentHandler: INExtension, FoldersIntentHandling {
    
    func loadData (name: String) throws -> [WidgetFolderHolder]? {
        
        var json: [WidgetFolderHolder]
        
        if let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra") {
                
            let fileURL = baseURL.appendingPathComponent(name)
                
            if let data = try? Data(contentsOf: fileURL) {
                // we're OK to parse!
                let decoder = JSONDecoder();
                
                json = try decoder.decode([WidgetFolderHolder].self, from: data)
                
                return json
                
            }
            
        }
        
        return nil
        
    }
    
    func provideFoldersOptionsCollection(for intent: FoldersIntent, with completion: @escaping (INObjectCollection<WidgetFolder>?, Error?) -> Void) {
        
        do {
            
            if let _folders: [WidgetFolderHolder] = try loadData(name: "folders.json") {
                
                let folders: [WidgetFolder] = _folders.map { WidgetFolder(identifier: $0.identifier, display: $0.displayString) }
                
                let collection: INObjectCollection<WidgetFolder> = INObjectCollection(items: folders)
                
                completion(collection, nil)
                
            }
            else {
                completion(nil, nil)
            }
            
        }
        catch {
            completion(nil, error)
        }
        
    }
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
