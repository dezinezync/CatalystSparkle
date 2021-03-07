//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models

struct ChangeSet {
    
    var changeToken: String!
    var changeTokenID: String!
    var customFeeds: [SyncChange]?
    var articles: [Article]?
    var reads: [UInt: Bool]?
    var pages: UInt
    
}
