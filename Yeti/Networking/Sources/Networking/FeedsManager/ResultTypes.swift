//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models

public struct GetUserResult: Hashable, Codable {
    
    public let user: User
    
}

public struct StartTrialResult: Hashable, Codable {
    
    public let status: Bool
    public let id: UInt?
    public let expiry: String?
    
}

public struct GetSubscriptionResult: Hashable, Codable {
    
    public let status: Bool
    public let subscription: Subscription
    
}

public struct StructureResult: Hashable, Codable {
    
    public let folders: [Folder]
    public let feeds: [UInt]
    
}

public struct GetFeedsResult: Hashable, Codable {
    
    public let feeds: [Feed]
    public let folders: [Folder]
    
}

public struct AddFeedResult: Hashable, Codable {
    
    public let feed: Feed
    
}

public struct GetArticlesResult: Hashable, Codable {
    
    public let articles: [Article]
    
}
