//
//  SyncCoordinator.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import BackgroundTasks
import Models
import UserNotifications
import Networking

#if os(macOS)
import AppKit.NSApplication
#else
import UIKit.UIApplication
#endif

/// The last sync date we stored or the one sent by the server.
private let SYNC_TOKEN = "syncToken-2.3.0"

/// The last sync token we stored or the one sent by the server.
private let SYNC_TOKEN_ID = "syncTokenID-2.3.0"

@objcMembers public final class SyncCoordinator: NSObject {
    
    public var totalProgress: Double = 1
    public var currentProgress: Double = 1
    
    public var backgroundCompletionHandler: (() -> Void)?
    #if os(iOS)
    public var backgroundFetchHandler: ((_ result: UIBackgroundFetchResult) -> Void)?
    #endif
    public var syncProgressCallback: ((_ progress: Double) -> Void)?
    
    fileprivate var syncQueue: OperationQueue?
    
    public var syncSetup = false
    
    public var isSyncing: Bool {
        return totalProgress != 0.0 && totalProgress < 0.99
    }
    
    #if os(iOS)
    public func setupSync(with task: BGAppRefreshTask?, completion: ((_ completed: Bool) -> Void)?) {
        
        let originalSyncProgressCallback = syncProgressCallback
        
        var cancelled = false
        
        syncProgressCallback = { [weak self] (progress) in
            
            guard let sself = self else {
                return
            }
            
            guard progress == 1 else {
                return
            }
            
            let completed = cancelled == false
            
            print("Background sync completed. Success: \(completed)")
            
            sself.backgroundCompletionHandler?()
            
            completion?(completed)
            
            task?.setTaskCompleted(success: completed)
            
            sself.syncProgressCallback = originalSyncProgressCallback
            
        }
        
        task?.expirationHandler = { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            guard let syncQueue = sself.syncQueue else {
                return
            }
            
            cancelled = true
            
            DispatchQueue.main.async {
                
                sself.backgroundCompletionHandler?()
                
                completion?(false)
                
                syncQueue.cancelAllOperations()
                
                task?.setTaskCompleted(success: false)
                
            }
            
        }
        
        syncSetup = false
        setupSync()
        
    }
    #endif
    
    public func setupSync () {
        
        guard syncSetup == false else {
            return
        }
        
        guard DBManager.shared.user != nil else {
            return
        }
        
        // check if sync has been setup on this device.
        DBManager.shared.uiConnection.asyncRead { [weak self] (t) in
            
            var token = t.object(forKey: SYNC_TOKEN, inCollection: .sync) as? String
            var tokenID = t.object(forKey: SYNC_TOKEN_ID, inCollection: .sync) as? String
            
            // if we don't have a token, we create one with an old date of 1993-03-11 06:11:00. Date was later changed to 2020-04-14 22:30 when sync was finalised.
            
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-MM-dd hh:mm:ss"
            
            if token == nil {
                
                // two weeks ago.
                let date = Date().addingTimeInterval((86400 * -14))
                
                token = formatter.string(from: date).base64Encoded()
                
            }
            else {
                
                // subtract half an hour from our previous token
                if let t = token,
                   let decoded = t.base64Decoded(),
                   var date = formatter.date(from: decoded) {
                    
                    date.addTimeInterval(3600 * -0.5)
                    
                    token = formatter.string(from: date).base64Encoded()
                    
                }
                
            }
            
            if tokenID == nil {
                tokenID = "0".base64Encoded()
            }
            
            guard let sself = self else {
                return
            }
            
            sself.syncSetup = true
            
            sself.syncNow(with: token!, tokenID: tokenID!, page: 1)
            
        }
        
    }
    
    public func syncNow(with token:String, tokenID: String, page: UInt) {
        
        if page == 1 {
            totalProgress = 1
            currentProgress = 0
            
            #if os(iOS)
            DispatchQueue.main.async { [weak self] in
                self?.internalProgressCallback(0, nil)
            }
            #endif
            
        }
        
        FeedsManager.shared.sync(with: token, tokenID: tokenID, page: page) { [weak self] (result) in
            
            switch result {
            case .success(let changeSet):
                
                guard let sself = self else {
                    return
                }
                
                sself.inProgressSyncToken = changeSet.changeToken
                sself.inProgressSyncTokenID = changeSet.changeTokenID
                
                if let reads = changeSet.reads, reads.count > 0 {
                    
                    sself.updateReads(reads: reads)
                    
                }
                
                if let custom = changeSet.customFeeds {
                    
                    sself.updateCustomFeeds(custom: custom)
                    
                }
                
                if let articles = changeSet.articles {
                    
                    sself.addArticles(articles: articles)
                    
                    if articles.count > 0 && page == 1 {
                        sself.totalProgress = Double(changeSet.pages)
                        sself.currentProgress += 1
                    }
                    else {
                        sself.currentProgress += 1
                    }
                    
                    if articles.count == 40,
                       (page < (sself.inProgressChangeSet ?? changeSet).pages)
                        || (page == 1 && page < changeSet.pages) {
                        
                        DispatchQueue.main.async {
                            sself.internalProgressCallback(sself.currentProgress/sself.totalProgress, changeSet)
                        }
                        
                        sself.syncNow(with: token, tokenID: tokenID, page: (page + 1))
                        
                    }
                    else {
                        
                        // syncing completed
                        DispatchQueue.main.async {
                            sself.internalProgressCallback(1, changeSet)
                        }
                        
                    }
                    
                }
                else {
                    DispatchQueue.main.async {
                        sself.internalProgressCallback(1, changeSet)
                    }
                }
                
            case .failure(let err):
                print(err)
                DispatchQueue.main.async {
                    self?.internalProgressCallback(1, nil)
                }
            }
            
        }
        
    }
    
    // MARK: - Internal Sync
    fileprivate var inProgressChangeSet: ChangeSet?
    fileprivate var inProgressSyncToken: String?
    fileprivate var inProgressSyncTokenID: String?
    
    lazy var internalProgressCallback: ((_ progress: Double, _ changeSet: ChangeSet?) -> Void) = { return { [weak self] (progress, changeSet) in
        
        guard let sself = self else {
            return
        }
        
        DispatchQueue.main.async {
            sself.syncProgressCallback?(progress)
        }
        
        if changeSet != nil && sself.inProgressChangeSet == nil {
            sself.inProgressChangeSet = changeSet
        }
        
        if progress == 1.0 {
            
            DBManager.shared.writeQueue.async {
                
                if let syncToken = sself.inProgressSyncToken,
                   let syncTokenID = sself.inProgressSyncTokenID {
                    
                    DBManager.shared.bgConnection.readWrite { (t) in
                        
                        t.setObject(syncToken, forKey: SYNC_TOKEN, inCollection: .sync)
                        
                        // non-nil and MA== is 0 in base64
                        if syncTokenID != "MA==" {
                            
                            t.setObject(syncTokenID, forKey: SYNC_TOKEN_ID, inCollection: .sync)
                            
                        }
                        
                    }
                    
                    sself.inProgressSyncToken = nil
                    sself.inProgressSyncTokenID = nil
                    
                }
                
                defer {
                    sself.backgroundFetchHandler = nil
                }
                
                if let changes = sself.inProgressChangeSet {
                    
                    DispatchQueue.main.async {
                        sself.backgroundFetchHandler?(.newData)
                    }
                    
                }
                else {
                    
                    DispatchQueue.main.async {
                        sself.backgroundFetchHandler?(.noData)
                    }
                    
                }
                
            }
            
        }
        
    } }()
    
    private func updateReads(reads: [String: Bool]) {
        
        guard reads.count > 0 else {
            return
        }
        
        DBManager.shared.bgConnection.asyncReadWrite { (t) in
            
            for tuple in reads {
                
                let (key, state) = tuple
                
                if let a = t.object(forKey: key, inCollection: .articles) as? Article,
                   var m = t.metadata(forKey: key, inCollection: .articles) as? ArticleMeta {
                    
                    a.read = state
                    m.read = state
                    
                    t.setObject(a, forKey: key, inCollection: .articles, withMetadata: m)
                    
                }
                
            }
            
        }
        
    }
    
    private func updateCustomFeeds (custom: [SyncChange]) {
        
        guard custom.count > 0 else {
            return
        }
        
        DBManager.shared.writeQueue.async { DBManager.shared.bgConnection.asyncReadWrite { (t) in
                
            for change in custom {
                
                guard let feed = DBManager.shared.feed(for: change.feedID) else {
                    continue
                }
                
                feed.localName = change.title
                
                if let title = change.title {
                    // doesn't matter if we overwrite the changes.
                    t.setObject(title, forKey: "\(change.feedID)", inCollection: .localNames)
                }
                else {
                    // remove the custom title
                    t.removeObject(forKey: "\(change.feedID)", inCollection: .localNames)
                }
                
            }
                
        } }
        
    }
    
    private func addArticles (articles: [Article]) {
        
        guard articles.count > 0 else {
            return
        }
        
        var grouped: [Feed: [Article]] = [:]
        
        // group articles by Feed
        for article in articles {
            
            guard let feed = DBManager.shared.feed(for: article.feedID) else {
                continue
            }
            
            let metadata = DBManager.shared.metadataForFeed(feed)
            
            if metadata.localNotifications == true {
                
                if grouped[feed] == nil {
                    grouped[feed] = []
                }
                
                // check if article exists in DB. If it does, assume notification was already sent for it.
                var a:Article? = nil
                    
                DBManager.shared.uiConnection.read { (t) in
                    a = t.object(forKey: "\(article.identifier!)", inCollection: .articles) as? Article
                }
                
                if a == nil {
                    grouped[feed]?.append(article)
                }
                
            }
            
        }
        
        if grouped.count > 0 {
            
            let filters: [String] = (DBManager.shared.user?.filters ?? []).map { $0 }
            
            for feed in grouped.keys {
                
                guard let articles = grouped[feed] else {
                    continue
                }
                
                if articles.count > 10 {
                    
                    let author = feed.displayTitle
                    let aTitle = "\(articles.count) New Articles"
                    
                    let userInfo = [
                        "feedID": "\(feed.feedID!)"
                    ]
                    
                    scheduleNotification(for: aTitle, subtitle: author, userInfo: userInfo, feedID: feed.feedID)
                    
                }
                else {
                    
                    for article in articles {
                        
                        guard (shouldShowNotification(for: article, filters: filters) == true) else {
                            continue
                        }
                        
                        var author = article.author
                        let aTitle = article.title ?? "Untitled"
                        
                        author = author != nil ? "\(feed.displayTitle) - \(author!)" : feed.displayTitle
                        
                        let cover = article.coverImage
                        let favicon = feed.faviconURI
                        
                        var userInfo = [
                            "feedID": "\(feed.feedID!)",
                            "articleID": "\(article.identifier!)"
                        ]
                        
                        if favicon != nil {
                            userInfo["favicon"] = favicon!.absoluteString
                        }
                        
                        if cover != nil {
                            userInfo["coverImage"] = cover!.absoluteString
                        }
                        
                        scheduleNotification(for: aTitle, subtitle: author!, userInfo: userInfo, feedID: feed.feedID)
                        
                    }
                    
                }
                
            }
            
        }
        
        DBManager.shared.add(articles: articles, strip: true)
        
    }
    
    private func shouldShowNotification(for article: Article, filters: [String]) -> Bool {
        
        // articles older than 2 weeks are marked as read
        if article.timestamp.timeIntervalSince(Date()) < -1209600 {
            return false
        }
        
        let title = (article.title ?? "").lowercased()
        
        var check = false
        
        for filter in filters {
            
            if title.contains(filter) {
                check = true
                break
            }
            
        }
        
        return check == false
        
    }
    
    private func scheduleNotification(for title: String, subtitle: String, userInfo: [String: String], feedID: UInt) {
        
        let date = Date().addingTimeInterval(2)
        let components = Calendar.current.dateComponents([
            .year, .month, .day,
            .hour, .minute, .second
        ], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subtitle
        
        content.categoryIdentifier = "NOTE_CATEGORY_ARTICLE"
        content.threadIdentifier = "\(feedID)"
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            
            guard let error = error else {
                return
            }
            
            print("Error adding local notification for: \(title) - \(subtitle)\n\(error)")
            
        }
        
    }
    
}
