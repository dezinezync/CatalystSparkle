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
    
    var state: FeedVCState = .empty {
        didSet {
            setupState()
        }
    }
    
    static var sorting: FeedSorting = FeedSorting(rawValue: (SharedPrefs.sortingOption as NSString).integerValue)!
    
    var sorting: FeedSorting = .descending {
        didSet {
            SharedPrefs.sortingOption = "\(sorting)"
            updateFeedSorting()
        }
    }
    
    var articles = NSMutableOrderedSet()
    
    static var filteringTag: UInt = 0
    
    lazy var DS: UITableViewDiffableDataSource<Int, Article> = {
       
        var ds = UITableViewDiffableDataSource<Int, Article>(tableView: tableView) { [weak self] (tableView, indexPath, article) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.identifier, for: indexPath) as! ArticleCell
            
            cell.configure(article, feedType: (self?.type)!)
            
            return cell
            
        }
        
        return ds
        
    }()

    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        
        setupFeed()
        setupData()
        
        if FeedVC.filteringTag == 0 {
            updateFeedSorting()
        }
        else {
            setupViews()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Setups
    
    func setupFeed() {
        
        ArticleCell.register(tableView)
        
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
    
    func updateFeedSorting() {
        
        let sortingOption = self.sorting
        
        DBManager.shared.readQueue.async { [weak self] in
            
            let sortingClosure = YapDatabaseViewSorting.withMetadataBlock { (t, g, c1, k1, m1, c2, k2, m2) -> ComparisonResult in
                
                guard let a1 = m1 as? ArticleMeta, let a2 = m2 as? ArticleMeta else {
                    return .orderedSame
                }

                let result = a1.timestamp.compare(other: a2.timestamp)
                
                if result == .orderedSame {
                    return result
                }
                
                if sortingOption.isAscending == true {
                    
                    return result
                    
                }
                
                if result == .orderedDescending {
                    return .orderedAscending
                }
                
                return .orderedDescending
                
            }
            
            DBManager.shared.bgConnection.readWrite { (t) in
                
                guard let sself = self else {
                    return
                }
                
                guard let txn = t.ext(DBManagerViews.feedView.rawValue) as? YapDatabaseAutoViewTransaction else {
                    return
                }
                
                FeedVC.filteringTag += 1
                
                txn.setSorting(sortingClosure, versionTag: "\(FeedVC.filteringTag)")
                
                DispatchQueue.main.async {
                    sself._didSetSortingOption()
                }
                
            }
            
        }
        
    }
    
    func _didSetSortingOption() {
        
        articles = NSMutableOrderedSet()
        state = .empty
        setupData()
        
        setupViews()
        
        total = -1
        currentPage = 0
        
    }
    
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
            
            // check filters
            
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
        
        DBManager.shared.writeQueue.async {
            
            if let _ = DBManager.shared.database.registeredExtension(dbFilteredViewName) as? YapDatabaseFilteredView {
                DBManager.shared.database.unregisterExtension(withName: dbFilteredViewName)
            }
            
        }
        
        DBManager.shared.writeQueue.async { [weak self] in
            
            FeedVC.filteringTag += 1
            
            let filteredView = YapDatabaseFilteredView(parentViewName: baseViewName.rawValue, filtering: filtering, versionTag: "\(FeedVC.filteringTag)")
            
            DBManager.shared.database.register(filteredView, withName: dbFilteredViewName)
            
            self?.dbFilteredView = filteredView
            
        }
        
        DBManager.shared.writeQueue.async { [weak self] in
            
            self?.loadNextPage()
            
        }
        
    }
    
    func setupState() {
        
        guard Thread.isMainThread == true else {
            DispatchQueue.main.async { [weak self] in
                self?.setupState()
            }
            return
        }
        
        // if the state is empty and there are no articles,
        // there is nothing to be done.
        guard state != .empty, articles.count > 0 else {
            showEmptyState()
            return
        }
        
        if state == .loading, articles.count == 0 {
            showLoadingState()
            return
        }
        
        if state == .errored, articles.count == 0 {
            // @TODO: Show error state
            return
        }
        
        removeEmptyState()
        
        if activityIndicator.isAnimating == true {
            activityIndicator.stopAnimating()
        }
        
        setupData()
        
    }
    
    func setupData() {
        
        if Thread.isMainThread == false {
            
            DispatchQueue.main.async { [weak self] in
                self?.setupData()
            }
            
            return
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, Article>()
        snapshot.appendSections([0])
        snapshot.appendItems(articles.map { $0 as! Article })
        
        DS.apply(snapshot, animatingDifferences: view.window != nil, completion: nil)
        
    }
    
    // MARK: - Updates
    func showEmptyState () {
        
        
        
    }
    
    func removeEmptyState() {
        
        
        
    }
    
    lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    
    func showLoadingState () {
        
        if (activityIndicator.superview == nil) {
            
            activityIndicator.sizeToFit()
            activityIndicator.hidesWhenStopped = true
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(activityIndicator)
            view.bringSubviewToFront(activityIndicator)
            
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.readableContentGuide.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.readableContentGuide.centerYAnchor)
            ])
            
        }
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
    }

}

extension FeedVC: ScrollLoading {
    
    func isLoading() -> Bool {
        return state.isLoading
    }
    
    func canLoadNext() -> Bool {
        return total == -1 || articles.count < total
    }
    
    func loadNextPage() {
        
        guard dbFilteredView != nil else {
            return
        }
        
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
                
                sself.articles.add(article)
                
            }
            
            sself.currentPage = page
            
            sself.state = .loaded

        }
        
    }
    
}
