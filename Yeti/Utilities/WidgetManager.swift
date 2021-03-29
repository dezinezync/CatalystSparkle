//
//  WidgetManager.swift
//  Elytra
//
//  Created by Nikhil Nigade on 20/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import Foundation
import WidgetKit
import Models
import Networking
import DBManager

@objcMembers public class WidgetManager: NSObject {
    
    public static func reloadAllTimelines() {
        
        WidgetCenter.shared.reloadAllTimelines();
        
    } 

    public static func reloadTimeline(name: String) {
        
        WidgetCenter.shared.reloadTimelines(ofKind: name)
        
        print("Reloaded \(name) widget")
        
    }
    
}

// @TODO: Move to Coordinator.swift
@objcMembers public class MyFeedsManager: NSObject {
    
    // MARK: - User
    static public func startFreeTrial(u: User?, completion: ((_ error: Error?, _ success: Bool) -> Void)?) {
        
        FeedsManager.shared.startFreeTrial { result in
            
            switch result {
            case .success(let sub):
                
                guard let user = DBManager.shared.user else {
                    completion?(nil, true)
                    return
                }
                
                user.subscription = sub
                
                DBManager.shared.user = user
                
                completion?(nil, true)
                
            case .failure(let error):
                completion?(error, false)
                
            }
            
        }
        
    }
    
    // MARK: - Feeds & Articles
    
    static public func feedFor(_ id: UInt) -> Feed? {
        
        return DBManager.shared.feed(for: id)
        
    }
    
    static public func metadataFor(feed:Feed) -> FeedMeta? {
        
        return DBManager.shared.metadataForFeed(feed)
        
    }
    
    static public func getContentFromDB(_ article: String) -> [Content]? {
        
        return DBManager.shared.content(for: article)
        
    }
    
    static public func getFullTextFromDB(_ article: String) -> [Content]? {
        
        return DBManager.shared.fullText(for: article)
        
    }
    
    static public func getFullText(_ article: Article, completion: ((_ error: Error?, _ fullText: Article?) -> Void)?) {
        
        if let fullText = MyFeedsManager.getFullTextFromDB(article.identifier) {
            
            let copy = article.codableCopy()
            copy.content = fullText
            
            completion?(nil, copy)
            
            return
        }
        
        FeedsManager.shared.getFullTextFor(article.identifier) { result in
            
            switch result {
            case .success(let a):
                DBManager.shared.add(fullText: a.content, articleID: a.identifier)
                completion?(nil, a)
            case .failure(let error):
                completion?(error, nil)
            }
            
        }
        
    }
    
    static public func getArticle(_ id: String, feedID: UInt, completion: ((_ error: Error?, _ article: Article?) -> Void)?) {
        
        if let article = DBManager.shared.article(for: id, feedID: feedID) {
            
            if article.content.count == 0 {
                
                // check if full text is loaded
                if let fulltext = DBManager.shared.fullText(for: article.identifier) {
                    article.content = fulltext
                    article.fulltext = true
                }
                else if let content = DBManager.shared.content(for: article.identifier) {
                    article.content = content
                    article.fulltext = false
                }
                
            }
            
            if article.content.count > 0 {
                completion?(nil, article)
                return
            }
            
        }
        
        FeedsManager.shared.getArticle(id) { result in

            switch result {
            case .failure(let error):
                completion?(error, nil)
                
            case .success(let article):
                DBManager.shared.add(article: article, strip: false)
                completion?(nil, article)
            }
            
        }
        
    }
    
    static public func purgeForFullResync (completion: (() -> Void)?) {
        
        DBManager.shared.purgeDataForResync(completion: completion)
        
    }
    
    static public func purgeForFeedResync (completion: (() -> Void)?) {
        
        DBManager.shared.purgeFeedsForResync(completion: completion)
        
    }
    
    // MARK: - User
    
    static public var user: User? {
        get {
            return DBManager.shared.user
        }
        set {
            DBManager.shared.user = newValue
        }
    }
    
    static public func getFilters(completion: ((_ error: Error?, _ filters: [String]?) -> Void)?) {
     
        FeedsManager.shared.getFilters { result in
            
            switch result {
            case .failure(let error):
                completion?(error, nil)
                
            case .success(let filters):
                completion?(nil, filters)
            }
            
        }
        
    }
    
    static public func addFilter(text: String, completion: ((_ error: Error?, _ status: Bool) -> Void)?) {
        
        FeedsManager.shared.addFilter(text) { result in
            
            switch result {
            case .failure(let error):
                completion?(error, false)
            
            case .success(let status):
                completion?(nil, status)
            }
            
        }
        
    }
    
    static public func deleteFilter(text: String, completion: ((_ error: Error?, _ status: Bool) -> Void)?) {
        
        FeedsManager.shared.deleteFilter(text) { result in
            
            switch result {
            case .failure(let error):
                completion?(error, false)
            
            case .success(let status):
                completion?(nil, status)
            }
            
        }
        
    }
    
}
