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
    
    var imageName: String {
        
        switch self {
        case .descending:
            return "arrow.down.circle"
        case .unreadDescending:
            return "arrow.down.circle.fill"
        case .ascending:
            return "arrow.up.circle"
        case .unreadAscending:
            return "arrow.up.circle.fill"
        }
        
    }
    
}

class FeedVC: UITableViewController {
    
    var type: FeedType! = .natural
    var feed: Feed? = nil
    
    var state: FeedVCState = .empty {
        didSet {
            if Thread.isMainThread == true {
                setupState()
            }
            else {
                DispatchQueue.main.sync { [weak self] in
                    self?.setupState()
                }
            }
        }
    }
    
    static var sorting: FeedSorting = FeedSorting(rawValue: (SharedPrefs.sortingOption as NSString).integerValue)! {
        didSet {
            
            guard oldValue != sorting else {
                return
            }
            
            SharedPrefs.setValue("\(sorting)", forKey: "sortingOption")
            
        }
    }
    
    weak var sortingBarItem: UIBarButtonItem? = nil
    
    var sorting: FeedSorting = FeedVC.sorting {
        didSet {
            
            guard oldValue != sorting else {
                return
            }
            
            FeedVC.sorting = sorting
            
            DispatchQueue.main.async { [weak self] in
                if let name = self?.sorting.imageName {
                    self?.sortingBarItem?.image = UIImage(systemName: name)
                }
            }
            
            updateFeedSorting()
        }
    }
    
    var articles = NSMutableOrderedSet()
    
    static var filteringTag: UInt = 0
    var sortingTag: UInt = 0
    
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
        setupNavBar()
        
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
    
    func setupNavBar() {
        
        var sortingActions: [UIAction] = [
            
            UIAction(title: "Unread - Latest First", image: UIImage(systemName: FeedSorting.unreadDescending.imageName), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] (_) in
                
                self?.sorting = .unreadDescending
                
            }),
            UIAction(title: "Unread - Oldest First", image: UIImage(systemName: FeedSorting.unreadAscending.imageName), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] (_) in
                
                self?.sorting = .unreadAscending
                
            })
            
        ]
        
        if type != .unread {
            
            sortingActions.append(UIAction(title: "All - Latest First", image: UIImage(systemName: FeedSorting.descending.imageName), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] (_) in
                
                self?.sorting = .descending
                
            }))
            
            sortingActions.append(UIAction(title: "All - Oldest First", image: UIImage(systemName: FeedSorting.ascending.imageName), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] (_) in
                
                self?.sorting = .ascending
                
            }))
            
        }
        
        let menu = UIMenu(title: "Sorting Options", image: nil, identifier: nil, options: [], children: sortingActions)
        
        let sortingItem = UIBarButtonItem(title: nil, image: UIImage(systemName: sorting.imageName), primaryAction: nil, menu: menu)
        
        navigationItem.rightBarButtonItems = [sortingItem]
        
        self.sortingBarItem = sortingItem
        
    }
    
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
            
            return true
            
//            guard metadata.read == false else {
//                return false
//            }
//
//            let now = Date().timeIntervalSince1970
//            let diff = now - metadata.timestamp
//
//            return diff <= 1209600
            
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
        
        // if the state is empty and there are no articles,
        // there is nothing to be done.
        guard state != .empty, articles.count > 0 else {
            showEmptyState()
            return
        }
        
        if total == -1 || (state == .loading && articles.count == 0) {
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
                
                sself.sortingTag += 1
                
                txn.setSorting(sortingClosure, versionTag: "\(sself.sortingTag)")
                
                DispatchQueue.main.async {
                    sself._didSetSortingOption()
                }
                
            }
            
        }
        
    }
    
    fileprivate var total: Int = -1
    fileprivate var currentPage: UInt = 0
    fileprivate var _loadNextRetries: UInt = 0
    
    func _didSetSortingOption() {
        
        articles = NSMutableOrderedSet()
        state = .empty
        setupData()
        
        total = -1
        currentPage = 0
        _loadNextRetries = 0
        
        setupViews()
        
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
        
        DBManager.shared.countsConnection.read { [weak self] (t) in
            
            guard let sself = self else {
                return
            }
            
            guard let txn = t.extension(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                
                if sself.currentPage == 0 {
                    
                    if sself._loadNextRetries < 2 {
                        
                        sself._loadNextRetries += 1
                        
                        DispatchQueue.main.async {
                            sself.loadNextPage()
                        }
                        
                    }
                    else {
                        sself.state = .errored
                    }
                    
                }
                
                return
            }
            
            let group = GroupNames.articles.rawValue
            
            if sself.total == -1 {
                sself.total = Int(txn.numberOfItems(inGroup: group))
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
