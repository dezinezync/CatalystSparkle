//
//  DBSearchManager.swift
//  
//
//  Created by Nikhil Nigade on 22/04/21.
//

import Foundation
import SwiftYapDatabase
import YapDatabase

extension DBManager {
    
    public func initSearch() {
        
        let versionString = "search:" + DB_VERSION_TAG
        
        let handler = YapDatabaseFullTextSearchHandler.withMetadataBlock { t, dict, col, key, meta in
            
        }
        
    }
    
}
