//
//  FeedVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 15/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Models
import DBManager
import YapDatabase
import SwiftYapDatabase

fileprivate let dbFilteredViewName = "feedFilteredView"

enum FeedVCState: Int {
    case empty
    case loading
    case loaded
    case errored
    
    var isLoading: Bool {
        return self == .loading || self == .errored
    }
}

enum FeedSorting: Int {
    case descending
    case ascending
    case unreadDescending
    case unreadAscending
    
    var isAscending: Bool {
        return self == .ascending || self == .unreadAscending
    }
    
    var isUnread: Bool {
        return self == .unreadAscending || self == .unreadDescending
    }
    
}

class FeedVC: UITableViewController {
    
    var type: FeedType! = .natural
    var feed: Feed? = nil
    var state: FeedVCState = .empty
    var sorting: FeedSorting = .descending
    
    var articles = Set<Article>()
    
    static var filteringTag: UInt = 0
    
    lazy var DS: UITableViewDiffableDataSource<Int, Article> = {
       
        var ds = UITableViewDiffableDataSource<Int, Article>(tableView: tableView) { (tableView, indexPath, article) -> UITableViewCell? in
            
            return UITableViewCell()
            
        }
        
        return ds
        
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFeed()
        setupViews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadNextPage()
    }
    
    // MARK: - Setups
    
    func setupFeed() {
        
        switch type {
        case .natural:
            guard let feed = feed else {
                return
            }
            
            self.title = feed.displayTitle
            
        default:
            break
        }
        
    }
    
    fileprivate var total: Int = -1
    fileprivate var currentPage: UInt = 0
    fileprivate var dbFilteredView: YapDatabaseFilteredView!
    
    func setupViews() {
        
        let baseViewName = sorting.isUnread == true ? DBManagerViews.unreadsView : DBManagerViews.articlesView
        
        let filtering = YapDatabaseViewFiltering.withMetadataBlock { [weak self] (t, g, c, k, m) -> Bool in
            
            guard let sself = self,
                  let feed = sself.feed else {
                return false
            }
            
            guard let metadata = m as? ArticleMeta else {
                return false
            }
            
            let feedID = feed.feedID
            
            guard metadata.feedID == feedID else {
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
            
            return diff <= 1209600
            
        }
        
        dbFilteredView = DBManager.shared.database.registeredExtension(dbFilteredViewName) as? YapDatabaseFilteredView
        
        if dbFilteredView != nil {
            DBManager.shared.database.unregisterExtension(withName: dbFilteredViewName)
        }
        
        FeedVC.filteringTag += 1
        
        let filteredView = YapDatabaseFilteredView(parentViewName: baseViewName.rawValue, filtering: filtering, versionTag: "\(FeedVC.filteringTag)")
        
        DBManager.shared.database.register(filteredView, withName: dbFilteredViewName)
        
        dbFilteredView = filteredView
        
    }
    
    // MARK: - Updates

}

extension FeedVC: ScrollLoading {
    
    func isLoading() -> Bool {
        return state.isLoading
    }
    
    func canLoadNext() -> Bool {
        return total == -1 || articles.count < total
    }
    
    func loadNextPage() {
        
        state = .loading
        
        DBManager.shared.uiConnection.asyncRead { [weak self] (t) in
            
            guard let sself = self else {
                return
            }
            
            guard let txn = t.extension(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                
                if sself.currentPage == 0 {
                    sself.state = .errored
                }
                
                return
            }
            
            let group = GroupNames.articles.rawValue
            
            if sself.total == -1 {
                sself.total = Int(txn.numberOfItems(inGroup: group))
            }
            
            guard sself.total > 0 else {
                return
            }
            
            let page = sself.currentPage + 1
            
            var range = NSMakeRange(((Int(page) - 1) * 20) - 1, 20)
            
            if page == 1 {
                range.location = 0
            }
            
            txn.enumerateRows(inGroup: group, with: [], range: range) { (a, b) -> Bool in
                return true
            } using: { (c, k, o, m, index, stop) in
                
                guard let article = o as? Article else {
                    return
                }
                
                sself.articles.insert(article)
                
            }
            
            sself.currentPage = page
            
            sself.state = .loaded

        }
        
    }
    
}
