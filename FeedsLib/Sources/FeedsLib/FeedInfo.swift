//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 17/02/21.
//

import Foundation

@objc public class FeedInfo: NSObject, Codable {
    var id: String? = nil
    var feedId: String? = nil
    var title: String? = nil
    var iconUrl: String? = nil
    var website: String? = nil
    var visualUrl: String? = nil
    var subscribers: Int = 0
    var updated: Date? = nil
    var lastUpdated: Date? = nil
    var priority: UInt = 0
}

@objc public class FeedInfoResponse: NSObject, Codable {
    
    var results: [FeedInfo]? = nil
    var queryType: String? = nil
    var scheme: String? = nil
    
}
