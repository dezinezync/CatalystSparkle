//
//  DBSearchManager.swift
//  
//
//  Created by Nikhil Nigade on 22/04/21.
//

import Foundation
import SwiftYapDatabase
import YapDatabase

let articlesFTSExtension = "fts:Articles"

extension DBManager {
    
    public func initSearch() {
        
        let versionTag = "search:" + DB_VERSION_TAG
        
        let columnNames = ["identifier", "title", "author", "summary"]
        
        let handler = YapDatabaseFullTextSearchHandler.withMetadataBlock { t, dict, col, key, meta in
            
        }
        
        let fts = YapDatabaseFullTextSearch(columnNames: columnNames, handler: handler, versionTag: versionTag)
        
        database.asyncRegister(fts, withName: articlesFTSExtension) {(ready) in
            
            if !ready {
                print("Error registering \(articlesFTSExtension) !!!")
            }
            
        }
        
    }
    
}
