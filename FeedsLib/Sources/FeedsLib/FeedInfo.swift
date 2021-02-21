//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 17/02/21.
//

import Foundation

@objc public class FeedInfo: NSObject, Codable {
    public var id: String? = nil
    public var feedId: String? = nil
    public var title: String? = nil
    public var iconUrl: String? = nil
    public var website: String? = nil
    public var visualUrl: String? = nil
    public var subscribers: Int? = 0
    public var updated: Date? = nil
    public var lastUpdated: Date? = nil
    public var priority: UInt? = 0
    
    public func toRecommendation () -> FeedRecommendation {
        
        let recco = FeedRecommendation()
        recco.title = title
        recco.id = id
        recco.iconUrl = iconUrl
        recco.visualUrl = visualUrl
        
        return recco
        
    }
    
}

@objc public class FeedInfoResponse: NSObject, Codable {
    
    public var results: [FeedInfo]? = nil
    public var queryType: String? = nil
    public var scheme: String? = nil
    
}
