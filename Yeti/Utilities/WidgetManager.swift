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
        
    }
    
}

// @TODO: Move to Coordinator.swift
@objcMembers public class MyFeedsManager: NSObject {
    
    static public func feedFor(_ id: UInt) -> Feed? {
        
        return DBManager.shared.feed(for: id)
        
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
            completion?(nil, article)
            return
        }
        
        FeedsManager.shared.getArticle(id) { result in
            
            switch result {
            case .failure(let error):
                completion?(error, nil)
                
            case .success(let article):
                completion?(nil, article)
            }
            
        }
        
    }
    
}
