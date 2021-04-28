//
//  DBManager+Search.swift
//  
//
//  Created by Nikhil Nigade on 22/04/21.
//

import Foundation
import SwiftYapDatabase
import YapDatabase
import DBManager

public let articlesFTSExtension = "fts:Articles"
fileprivate let DB_VERSION_TAG = "2021-04-27 09:03AM"

extension DBManager {
    
    public func initSearch() {
        
        let versionTag = "search:" + DB_VERSION_TAG
        
        let columnNames = ["identifier", "title", "author"]
        
        let handler = YapDatabaseFullTextSearchHandler.withMetadataBlock { t, dict, col, key, meta in
            
            if let articleMeta = meta as? ArticleMeta {
               
                dict["identifier"] = key as NSString
                
                let wordCloud: [String] = articleMeta.titleWordCloud ?? [""]
                
                dict["title"] = (wordCloud.count == 1 ? wordCloud[0] : wordCloud.joined()) as NSString
                
                if let author = articleMeta.author {
                    dict["author"] = author as NSString
                }
                
            }
            else {
               // Don't need to index this item.
               // So we simply don't add anything to the dict.
            }
            
        }
        
        let fts = YapDatabaseFullTextSearch(columnNames: columnNames, handler: handler, versionTag: versionTag)
        
        database.asyncRegister(fts, withName: articlesFTSExtension) {(ready) in
            
            if !ready {
                print("Error registering \(articlesFTSExtension) !!!")
            }
            
        }
        
    }
    
}
