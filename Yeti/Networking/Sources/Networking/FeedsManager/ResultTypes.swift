//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models

public struct GetUserResult: Hashable, Codable {
    
    let user: User
    
}

public struct StartTrialResult: Hashable, Codable {
    
    let status: Bool
    let id: UInt?
    let expiry: String?
    
}

public struct GetSubscriptionResult: Hashable, Codable {
    
    let status: Bool
    let subscription: Subscription
    
}

public struct StructureResult: Hashable, Codable {
    
    let folders: [Folder]
    let feeds: [UInt]
    
}

public struct GetFeedsResult: Hashable, Codable {
    
    let feeds: [Feed]
    let folders: [Folder]
    
}

public struct AddFeedResult: Hashable, Codable {
    
    let feed: Feed
    
}

public struct GetArticlesResult: Hashable, Codable {
    
    let articles: [Article]
    
}
