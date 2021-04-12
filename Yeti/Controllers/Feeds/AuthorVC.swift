//
//  AuthorVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 06/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Combine
import DBManager
import YapDatabase
import SwiftYapDatabase
import Dynamic

class AuthorVC: FeedVC {

    var author: String!
    @Published var unread: UInt = 0
    
    override func viewDidLoad() {
        
        type = .author
        
        super.viewDidLoad()
        
        NotificationCenter.default.publisher(for: .DBManagerDidUpdate)
            .receive(on: DBManager.shared.writeQueue)
            .sink { [weak self] note in
                
                guard let sself = self,
                      let notifications = note.userInfo?[notificationsKey] as? [Notification],
                      notifications.count > 0 else {
                    return
                }
                
                // check if any of the notifications has a change for
                // the unreads view. If we do, update the counters.
                var hasChanges: Bool = DBManager.shared.countsConnection.hasMetadataChange(forCollection: CollectionNames.articles.rawValue, in: notifications)
                
                guard hasChanges == true else { return }
                
                // check if there are notifications specific to our view.
                if let con =  DBManager.shared.countsConnection.ext(dbFilteredViewName) as? YapDatabaseFilteredViewConnection {
                    
                    hasChanges = con.hasChanges(for: notifications)
                    
                }
                
                guard hasChanges == true else { return }
                
                CoalescingQueue.standard.add(sself, #selector(sself.updateCounters))
                
            }
            .store(in: &cancellables)
        
        updateCounters()
        
    }
    
    #if targetEnvironment(macCatalyst)
    public override func setupTitleView() {
        
        guard let title: String = self.title else {
            return
        }
        
        guard let window = coordinator?.innerWindow else {
            return
        }
        
        super.setupTitleView()
        
        Dynamic(window).title = title
        
        $unread
            .receive(on: DispatchQueue.main)
            .sink { [weak self] unread in
                
                guard let sself = self,
                      let swindow = sself.coordinator?.innerWindow else {
                          return
                      }
                
                sself.totalUnread = unread
                
                Dynamic(swindow).subtitle = "\(unread) Unread"
                
            }
            .store(in: &cancellables)
        
    }
    #endif
    
    // MARK: - Setup
    
    override func setupFeed() {
        
        super.setupFeed()
        
        // case doesn't have implementation for folder.
        
        self.title = author
        
        self.titleView?.titleLabel.text = author
        
        $unread
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (unread) in
                
                guard let sself = self else {
                    return
                }
                
                sself.titleView?.countLabel.text = "\(unread) Unread\(unread == 1 ? "" : "s")"
                
            }
            .store(in: &cancellables)
        
    }
    
    override var dbAutoViewName: String {
        
        let sortingKey: Int = self.sorting.isAscending == true ? 1 : 2;
        
        let feedKey: String = "feed:\(feed!.feedID!):\(author!)"
        
        return "feedFilteredView::\(feedKey)::\(sortingKey)"
        
    }
    
    override func setupViews() {
        
        let baseViewName = dbAutoViewName
        
        let filtering = YapDatabaseViewFiltering.withMetadataBlock { [weak self] (t, g, c, k, m) -> Bool in
            
            guard let sself = self,
                  let metadata = m as? ArticleMeta else {
                return false
            }
            
            guard metadata.author == sself.author else {
                return false
            }
            
            guard sself.sorting.isUnread == true else {
                return true
            }
            
            guard metadata.read == false else {
                return false
            }

            let now = Date().timeIntervalSince1970
            let diff = now - metadata.timestamp
            
            if diff < 0 {
                // future date
                return true
            }

            return diff <= 1209600
            
        }
        
        DBManager.shared.writeQueue.async {
            
            if let _ = DBManager.shared.database.registeredExtension(dbFilteredViewName) as? YapDatabaseFilteredView {
                DBManager.shared.database.unregisterExtension(withName: dbFilteredViewName)
            }
            
        }
        
        DBManager.shared.writeQueue.async { [weak self] in
            
            FeedVC.filteringTag += 1
            
            let filteredView = YapDatabaseFilteredView(parentViewName: baseViewName, filtering: filtering, versionTag: "\(FeedVC.filteringTag)")
            
            DBManager.shared.database.register(filteredView, withName: dbFilteredViewName)
            
            self?.dbFilteredView = filteredView
            
        }
        
        DBManager.shared.writeQueue.async { [weak self] in
            
            self?.loadNextPage()
            
        }
        
    }

    // MARK: - State
    override var emptyViewDisplayTitle: String {
        return author
    }
    
    func updateCounters() {
        
        DBManager.shared.writeQueue.async {
            
            DBManager.shared.countsConnection.asyncRead { [weak self] t in
                
                guard let sself = self,
                      let txn = t.ext(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                    return
                }
                
                let total = txn.numberOfItems(inGroup: GroupNames.articles.rawValue)
                
                let now = Date().timeIntervalSince1970
                
                var counting: UInt = 0
                
                txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, Int(total))) { _, _ in
                    return true
                } using: { c, k, m, index, stop in
                    
                    guard let metadata = m as? ArticleMeta else { return }
                    
                    guard metadata.read == false else {
                        return
                    }
                    
                    let diff = now - metadata.timestamp
                    
                    if diff <= 1209600 {
                        counting += 1
                    }
                    
                }
                
                sself.unread = counting
                
            }
            
        }
        
    }

}
