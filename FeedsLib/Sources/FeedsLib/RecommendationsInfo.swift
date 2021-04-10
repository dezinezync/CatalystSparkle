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
    public var feedId: String? = nil
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
    public var summary: String? = nil
    public var accentColor: String? = nil
    public var logo: String? = nil
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case relevanceScore
        case id
        case feedId
        case title
        case topics
        case updated
        case website
        case iconUrl
        case coverUrl
        case visualUrl
        case contentType
        case language
        case coverColor
        case workmark
        case summary = "description"
        case accentColor
        case logo
    }
    
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
