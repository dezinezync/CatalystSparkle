//
//  BookmarksCoordinator+Impl.swift
//  Elytra
//
//  Created by Nikhil Nigade on 06/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import DBManager
import YapDatabase
import SwiftYapDatabase
import Models
import Networking

extension BookmarksCoordinator {
    
    public func start() {
        
        DispatchQueue.global().async {
            self.setup()
        }
        
    }
    
    func setup() {
        
        guard let userID = user.userID else {
            print("Error starting bookmarks coordinator. No userID on user.")
            return
        }
        
        // get existing bookmarks
        var existing: [String] = []
        
        DBManager.shared.uiConnection.read { t in
            
            guard let txn = t.ext(DBManagerViews.bookmarksView.rawValue) as? YapDatabaseFilteredViewTransaction else { return }
            
            let count = txn.numberOfItems(inGroup: GroupNames.articles.rawValue)
            
            if count > 0 {
                
                txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, Int(count))) { _, _ in
                    return true
                } using: { c, k, m, count, stop in
                    
                    existing.append(k)
                    
                }
                
            }
            
        }
        
        let existingStr = existing.joined(separator: ",")
        
        let body: [String: String] = [
            "existing": existingStr
        ]
        
        let query: [String: String] = ["userID": "\(userID)"]
        
        FeedsManager.shared.session.POST(path: "/bookmarked", query: query, body: body, resultType: [String: [Int]].self) { [weak self] result in
            
            switch result {
            case .failure(let error):
                print("Bookmarks Coordinator: Error coordinating bookmarks: \(error)")
                
            case .success(let (response, result)):
                
                guard let response = response else {
                    return
                }
                
                if response.statusCode >= 300 {
                    // no changes
                    print("Bookmarks Coordinator: No changes in bookmarks. Exiting.")
                    return
                }
                
                guard let result = result else {
                    return
                }
                
                let bookmarked: [String] = (result["bookmarks"] ?? []).map { "\($0)" }
                let deleted: [String] = (result["deleted"] ?? []).map { "\($0)" }
                
                DispatchQueue.main.async {
                    self?.deleteBookmarks(deleted: deleted)
                }
                
                DispatchQueue.main.async {
                    self?.addBookmarks(added: bookmarked)
                }
                
            }
            
        }
        
    }
    
    func deleteBookmarks(deleted: [String]) {
        
        guard deleted.count > 0 else {
            return
        }
        
        DBManager.shared.bgConnection.readWrite { t in
            
            guard let txn = t.ext(DBManagerViews.bookmarksView.rawValue) as? YapDatabaseFilteredViewTransaction else { return }
            
            let total: UInt = UInt(deleted.count)
            var counted: UInt = 0
            
            let allCount = Int(txn.numberOfItems(inGroup: GroupNames.articles.rawValue))
            
            var items: [String: (ArticleMeta, Article)] = [:]
            
            txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, allCount)) { _, _ in
                return true
            } using: { c, k, m, index, stop in
                
                guard var metadata = m as? ArticleMeta else { return }
                
                if deleted.contains(k) == true {
                    
                    if let obj = t.object(forKey: k, inCollection: c) as? Article {
                        
                        metadata.bookmarked = false
                        
                        items[k] = (metadata, obj)
                        
                    }
                    
                    counted += 1
                    
                }
                
                if counted == total {
                    stop.pointee = true
                }
                
            }

            if items.count > 0 {
                
                for (key, item) in items {
                    
                    let (m, o) = item
                    
                    o.bookmarked = false
                    
                    t.setObject(o, forKey: key, inCollection: CollectionNames.articles.rawValue, withMetadata: m)
                    
                }
                
            }
            
        }
        
    }
    
    func addBookmarks(added: [String]) {
        
        guard added.count > 0 else {
            return
        }
        
        var toProcess: [String] = Array(added)
        
        DBManager.shared.bgConnection.readWrite { t in
            
            guard let txn = t.ext(DBManagerViews.bookmarksView.rawValue) as? YapDatabaseFilteredViewTransaction else { return }
            
            let total: UInt = UInt(added.count)
            var counted: UInt = 0
            
            let allCount = Int(txn.numberOfItems(inGroup: GroupNames.articles.rawValue))
            
            var items: [String: (ArticleMeta, Article)] = [:]
            
            txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, allCount)) { _, _ in
                return true
            } using: { c, k, m, index, stop in
                
                guard var metadata = m as? ArticleMeta else { return }
                
                if added.contains(k) == true {
                    
                    if let obj = t.object(forKey: k, inCollection: c) as? Article {
                        
                        metadata.bookmarked = true
                        
                        items[k] = (metadata, obj)
                        
                    }
                    
                    counted += 1
                    
                }
                
                if counted == total {
                    stop.pointee = true
                }
                
            }

            if items.count > 0 {
                
                for (key, item) in items {
                    
                    let (m, o) = item
                    
                    o.bookmarked = true
                    
                    t.setObject(o, forKey: key, inCollection: CollectionNames.articles.rawValue, withMetadata: m)
                    
                }
                
                toProcess = toProcess.filter { items.keys.contains($0) == false }
                
            }
            
        }
        
        guard toProcess.count > 0 else {
            return
        }
        
        // we do not have these articles in our cache. So let's fetch them and add them.
        for articleID in toProcess {
            
            FeedsManager.shared.getArticle(articleID) { result in
                
                if case .success(let article) = result {
                    
                    if article.bookmarked == false {
                        article.bookmarked = true
                    }
                    
                    DBManager.shared.add(article: article, strip: true)
                    
                }
                else {
                    print("Bookmarks Coordinator: Failed to fetch article with ID: \(articleID)")
                }
                
            }
            
        }
        
    }
    
}
