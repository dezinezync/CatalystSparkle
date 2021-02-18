//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 17/02/21.
//

import Foundation

@objc public class FeedRecommendation: NSObject, Codable {
    public var relevanceScore: Double? = 0
    public var id: String? = nil
    public var title: String? = nil
    public var topics: [String]? = nil
    public var updated: Date? = nil
    public var website: String? = nil
    public var iconUrl: String? = nil
    public var coverUrl: String? = nil
    public var visualUrl: String? = nil
    public var contentType: String? = nil
    public var language: String? = nil
    public var coverColor: String? = nil
    public var workmark: String? = nil
}

@objc public class RelatedTopic: NSObject, Codable {
    
    public var topic: String? = nil
    public var focusScore: Double? = 0
    
}

@objc public class RecommendationsResponse: NSObject, Codable {
    
    public var feedInfos: [FeedRecommendation]? = nil
    public var bestFeedId: String? = nil
    public var language: String? = nil
    public var topic: String? = nil
    
}
