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
import Networking
import Combine

fileprivate let dbFilteredViewName = "feedFilteredView"

class ArticlesDatasource: UITableViewDiffableDataSource<Int, Article> {

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}

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

enum MarkDirection {
    case newer
    case older
}

class FeedVC: UITableViewController {
    
    var type: FeedType! = .natural
    var feed: Feed? = nil
    var cancellables = [AnyCancellable]()
    
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
    
    var loadOnReady: UInt?
    
    lazy var DS: ArticlesDatasource = {
       
        var ds = ArticlesDatasource(tableView: tableView) { [weak self] (tableView, indexPath, article) -> UITableViewCell? in
            
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
    
    deinit {
        DBManager.shared.database.unregisterExtension(withName: dbFilteredViewName)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Setups
    weak var titleView: FeedTitleView?
    
    func setupFeed() {
        
        ArticleCell.register(tableView)
        
        switch type {
        case .natural:
            guard let feed = feed else {
                return
            }
            
            self.title = feed.displayTitle
            
            let titleView = FeedTitleView()
            
            feed.displayTitle.publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (_) in
                    
                    guard let sself = self,
                          let tv = sself.titleView,
                          let f = sself.feed else {
                        return
                    }
                    
                    tv.titleLabel.text = f.displayTitle
                    
                }
                .store(in: &cancellables)
            
            feed.$unread.receive(on: DispatchQueue.main)
                .sink { [weak self] (unread) in
                    
                    guard let sself = self else {
                        return
                    }
                    
                    let count = unread ?? 0
                    
                    sself.titleView?.countLabel.text = "\(count) Unread\(count == 1 ? "" : "s")"
                    
                }
                .store(in: &cancellables)
            
            if let image = feed.faviconImage {
                titleView.faviconView.image = image
            }
            else if let url = feed.faviconProxyURI(size: 24) {
                titleView.faviconView.sd_setImage(with: url) { (image, _, _, _) in
                    
                    if let image = image {
                        feed.faviconImage = image
                    }
                    
                }
            }
            
            navigationItem.titleView = titleView
            self.titleView = titleView
            
        default:
            break
        }
        
    }
    
    func setupNavBar() {
        
        navigationItem.rightBarButtonItems = self.rightBarButtonItems()
        
        
        
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
        
        let isEmpty = DS.snapshot().numberOfItems == 0
        let animated = isEmpty == true ? false : (view.window != nil)
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, Article>()
        snapshot.appendSections([0])
        snapshot.appendItems(articles.map { $0 as! Article })
        
        DS.apply(snapshot, animatingDifferences: animated, completion: nil)
        
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
    
    func updateVisibleCells () {
        
        var snapshot = DS.snapshot()
        
        guard let visible = tableView.indexPathsForVisibleRows,
              visible.count > 0 else {
            return
        }
        
        var items = [Article]()
        
        visible.forEach {
            
            if let item = DS.itemIdentifier(for: $0) {
                items.append(item)
            }
            
        }
        
        snapshot.reloadItems(items)
        
        DS.apply(snapshot, animatingDifferences: tableView.window != nil, completion: nil)
        
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
            
            var context: UInt = 0
            
            txn.enumerateRows(inGroup: group, with: [], range: range) { (a, b) -> Bool in
                return true
            } using: { (c, k, o, m, index, stop) in
                
                guard let article = o as? Article else {
                    return
                }
                
                sself.articles.add(article)
                context += 1
                
            }
            
            sself.currentPage = page
            
            if context < 20 {
                // we expected 20. so check.
                
                if sself.articles.count != sself.total {
                    
                    // some articles could not be fetched.
                    // so lets correct our total
                    sself.total -= (20 - Int(context))
                    
                }
                
            }
            
            sself.state = .loaded

        }
        
    }
    
}

// MARK: - Actions
extension FeedVC {
    
    @objc func didTapMarkAll( _ sender: UIBarButtonItem?) {
        
        guard SharedPrefs.showMarkReadPrompts == false else {
            
            AlertManager.showAlert(title: "Mark All Read?", message: "Are you sure you want to mark all unread articles as read?", confirm: "Yes", confirmHandler: { [weak self] (_) in
                
                self?.markAllRead(sender)
                
            }, cancel: "Cancel", cancelHandler: nil, from: self)
            
            return
        }
        
        markAllRead(sender)
        
    }
    
    func markAllRead( _ sender: UIBarButtonItem?) {
        
        DBManager.shared.bgConnection.asyncReadWrite { [weak self] (t) in
            
            guard let txn = t.ext(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                return
            }
            
            var items = [String: Article]()
            var feedsMapping = [UInt: UInt]()
            
            let count = txn.numberOfItems(inGroup: GroupNames.articles.rawValue)
            
            guard count > 0 else {
                return
            }
            
            let calendar = Calendar.current
            var inToday: UInt = 0
            
            // get all unread items from this view
            txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, Int(count))) { (_, _) -> Bool in
                return true
            } using: { (c, k, m, index, stop) in
                
                guard let metadata = m as? ArticleMeta else {
                    return
                }
                
                guard metadata.read == false else {
                    return
                }
                
                guard let o = t.object(forKey: k, inCollection: c) as? Article else {
                    return
                }
                
                items[k] = o
                
                if feedsMapping[metadata.feedID] == nil {
                    feedsMapping[metadata.feedID] = 0
                }
                
                feedsMapping[metadata.feedID]! += 1
                
                if calendar.isDateInToday(Date(timeIntervalSince1970: metadata.timestamp)) == true {
                    inToday += 1
                }
                
            }
            
            guard let sself = self else {
                return
            }

            print("Marking \(items.count) items as read")
            
            sself.markRead(items, inToday: inToday, feedsMapping: feedsMapping) { [weak self] (count, feed) in
                
                feed.unread -= count
                
                (self?.articles.objectEnumerator().allObjects as! [Article]).forEach { $0.read = true }
                
            } completion: { [weak self] in
                
                self?.updateVisibleCells()
                
            }
            
        }
        
    }
    
    func markRead(_ inItems: [String: Article], inToday: UInt?, feedsMapping: [UInt: UInt]?, each:(( _ count: UInt, _ feed: Feed) -> Void)?, completion:(() -> Void)?) {
        
        var items = inItems
        
        FeedsManager.shared.markRead(true, items: items.values.map { $0 }) { [weak self] (result) in
            
            guard let sself = self else {
                return
            }
            
            switch result {
            
            case .failure(let err):
                
                let error = (err as NSError)
                
                AlertManager.showAlert(title: "An Error Occurred", message: error.localizedDescription, confirm: nil, cancel: "Okay")
                
                return
                
            case .success(let results):
                
                // get all successful items
                let succeeded = results
                    .filter { $0.status == true }
                    .map { String($0.articleID) }
                
                items = items.filter({ (elem) -> Bool in
                    
                    return succeeded.contains(elem.key)
                    
                })
                
                for i in items { i.value.read = true }
                
                sself.mainCoordinator?.totalUnread -= UInt(items.count)
                
                if inToday != nil {
                    sself.mainCoordinator?.totalToday -= inToday!
                }
                
                DBManager.shared.add(articles: items.values.map { $0 }, strip: false)
                
                if feedsMapping != nil {
                    for (key, count) in feedsMapping! {
                        
                        guard let feed = DBManager.shared.feedForID(key) else {
                            print("Feed not found for ID:", key)
                            continue
                        }
                        
                        DispatchQueue.main.async {
                            
                            each?(count, feed)
                            
                        }
                        
                    }
                }
                
                DispatchQueue.main.async {
                    
                    completion?()
                    
                }
            
            }
            
        }
        
    }
    
    @objc func didTapBack() {
        
        navigationController?.popToRootViewController(animated: true)
        
    }
    
    @objc func didTapTitleView() {
        
        // @TODO 
        
    }
    
    @objc func markAllNewerRead(_ indexPath: IndexPath) {
        
        markDirectional(.newer, indexPath: indexPath)
        
    }
    
    @objc func markAllOlderRead(_ indexPath: IndexPath) {
        
        markDirectional(.older, indexPath: indexPath)
        
    }
    
    func markDirectional(_ direction: MarkDirection, indexPath: IndexPath) {
        
        let sorting = self.sorting
        var feed: String?
        
        if type == .unread { feed = "unread" }
        else if type == .today { feed = "today" }
        else if type == .natural { feed = "\(self.feed!.feedID!)" }
        
        guard feed != nil else {
            return
        }
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return
        }
        
        var isDescending = sorting.isAscending == false
        isDescending = (direction == .newer && isDescending) || (direction == .older && isDescending == false)
        
        let options: NSEnumerationOptions = isDescending == false ? .reverse : []
        
        // our unreads array count can't exceed this so we
        // can use this as a control to stop enumerating.
        let grandTotal = mainCoordinator?.totalUnread ?? 0
        
        DBManager.shared.readQueue.async { [weak self] in
            
            DBManager.shared.uiConnection.asyncRead { (t) in
                
                guard let txn = t.ext(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                    return
                }
                
                let localID = item.identifier!
                
                let localTimestamp = item.timestamp.timeIntervalSince1970
                
                let total = Int(txn.numberOfItems(inGroup: GroupNames.articles.rawValue))
            
                var unreads = [String: Article]()
                var feedsMapping = [UInt: UInt]()
                var inToday: UInt = 0
                
                txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: options, range: NSMakeRange(0, total)) { (_, _) -> Bool in
                    return true
                } using: { (c, k, meta, index, stop) in
                    
                    guard let metadata = meta as? ArticleMeta,
                          metadata.read == false else {
                        return
                    }
                    
                    let keyID = UInt((k as NSString).integerValue)
                    let keyTimestamp = metadata.timestamp
                    
                    if direction == .newer {
                        
                        // the item's time cannot be higher than
                        // the reference item's time.
                        if keyTimestamp < localTimestamp {
                            return
                        }
                        else if keyTimestamp == localTimestamp,
                                keyID < localID {
                            
                            // if the times are the same, we compare by
                            // the identifier of the two items.
                            return
                            
                        }
                        
                    }
                    else {
                        
                        if keyTimestamp > localTimestamp {
                            return
                        }
                        else if keyTimestamp == localTimestamp,
                                keyID > localID {
                            return
                        }
                        
                    }
                    
                    if let item = t.object(forKey: k, inCollection: c) as? Article {
                        
                        unreads[k] = item
                        
                        if feedsMapping[metadata.feedID] == nil {
                            feedsMapping[metadata.feedID] = 0
                        }
                        
                        feedsMapping[metadata.feedID]! += 1
                        
                        if Calendar.current.isDateInToday(item.timestamp) {
                            inToday += 1
                        }
                        
                    }
                    
                    if grandTotal == unreads.count {
                        stop.pointee = true
                    }
                    
                }
                
                guard unreads.count > 0 else {
                    return
                }
                
                #if DEBUG
                print("IDs: ", unreads.map { $0.key })
                #endif
                
                guard let sself = self else {
                    return
                }
                
                sself.markRead(unreads, inToday: inToday, feedsMapping: feedsMapping, each: nil) {
                    
                    sself.reloadCells(from: indexPath, down: (options == .reverse))
                    
                }
                
            }
            
        }
        
    }
    
    func reloadCells(from indexPath: IndexPath, down:Bool) {
        
        var snapshot = self.DS.snapshot()
        
        var identifiers = [Article]()
        
        if down == true {
            
            // all current cells till the end of the dataset
            for index in (indexPath.row..<snapshot.numberOfItems) {
                
                let ip = IndexPath(row: index, section: indexPath.section)
                
                if let item = DS.itemIdentifier(for: ip) {
                    
                    identifiers.append(item)
                    
                }
                
            }
            
        }
        else {
            
            // current upto the 0th index
            for index in (0...indexPath.row) {
                
                let ip = IndexPath(row: index, section: indexPath.section)
                
                if let item = DS.itemIdentifier(for: ip) {
                    
                    identifiers.append(item)
                    
                }
                
            }
            
        }
        
        snapshot.reloadItems(identifiers)
        
        DS.apply(snapshot, animatingDifferences: view.window != nil, completion: nil)
        
    }
    
    func reloadVisibleCells () {
        
        guard Thread.isMainThread == true else {
            
            DispatchQueue.main.async { [weak self] in
                self?.reloadVisibleCells()
            }
            
            return
            
        }
        
        var snapshot = DS.snapshot()
        
        var visible = [Article]()
        
        if let indices = tableView.indexPathsForVisibleRows,
           indices.count > 0 {
            
            for indexPath in indices {
                
                if let item = DS.itemIdentifier(for: indexPath) {
                    
                    visible.append(item)
                    
                }
                
            }
            
        }
        
        snapshot.reloadItems(visible)
        
        DS.apply(snapshot, animatingDifferences: view.window != nil, completion: nil)
        
    }
    
}

extension FeedVC: BarPositioning {
    
    func rightBarButtonItems() -> [UIBarButtonItem]? {
        
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
        
        let allReadItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(didTapMarkAll(_:)))
        
        self.sortingBarItem = sortingItem
        
        return [allReadItem, sortingItem]
        
    }
    
    var toolbarBarItems: [UIBarButtonItem]? {
        
        guard SharedPrefs.useToolbar == true else {
            return nil
        }
        
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        let fixed = UIBarButtonItem(systemItem: .fixedSpace)
        fixed.width = 24
        
        guard let right = rightBarButtonItems() else {
            return nil
        }
        
        let items: [UIBarButtonItem] = right.enumerated()
            .map { (index, item) -> [UIBarButtonItem] in
            
            if index == 0 {
                return [item]
            }
            
            return [flex, item]
            
        }.flatMap { $0 }
        
        return items
        
    }
    
}

// MARK: - Article Provider
extension FeedVC {
    
    @objc func loadArticle() {
        
        guard let articleID = loadOnReady,
              let feed = self.feed else {
            return
        }
        
        let snapshot = DS.snapshot()
        
        guard snapshot.numberOfItems > 0 else {
            return
        }
        
        var index = NSNotFound
        
        for (idx, item) in snapshot.itemIdentifiers.enumerated() {
            
            if item.identifier == articleID {
                index = idx
                break
            }
            
        }
        
        loadOnReady = nil
        
        guard index != NSNotFound else {
            
            let a = Article()
            a.identifier = articleID
            a.feedID = feed.feedID
            
            showArticle(a)
            
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            
            guard let sself = self,
                  let tableView = sself.tableView else {
                return
            }
            
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
            
            sself.tableView(tableView, didSelectRowAt: indexPath)
            
        }
        
    }
    
    @objc func showArticle(_ article: Article) {
        
        // @TODO
        
    }
    
    @objc func userMarkedArticle(_ article: Article, read: Bool) {
        
        FeedsManager.shared.markRead(true, items: [article]) { [weak self] (result) in
            
            switch result {
            case .failure(let error):
                AlertManager.showGenericAlert(withTitle: "Error Marking \(read ? "Read" : "Unread")", message: error.localizedDescription)
                
            case .success(_):
                
                article.read = read
                
                DBManager.shared.add(article: article, strip: false)
                
                self?.reloadVisibleCells()
                
                let inToday = Calendar.current.isDateInToday(article.timestamp)
                
                let feed = DBManager.shared.feedForID(article.feedID)
                
                if read == true {
                    
                    self?.mainCoordinator?.totalUnread -= 1
                    
                    if inToday { self?.mainCoordinator?.totalToday -= 1 }
                    
                    feed?.unread -= 1
                    
                }
                else {
                    
                    self?.mainCoordinator?.totalUnread += 1
                    
                    if inToday { self?.mainCoordinator?.totalToday += 1 }
                    
                    feed?.unread += 1
                    
                }
                
            }
            
        }
        
    }
    
    @objc func userMarkedArticle(_ article: Article, bookmark: Bool) {
        
        FeedsManager.shared.mark(bookmark, item: article) { [weak self] (result) in
            
            switch result {
            
            case .failure(let error):
                AlertManager.showGenericAlert(withTitle: "Error \(bookmark ? "Bookmark" : "Unbookmark")ing", message: error.localizedDescription)
            
            case .success(let result):
                
                guard result.status == true else {
                    
                    AlertManager.showGenericAlert(withTitle: "Error \(bookmark ? "Bookmark" : "Unbookmark")ing", message: "An unknown error occurred when performing this action.")
                    
                    return
                    
                }
                
                article.bookmarked = bookmark
                DBManager.shared.add(article: article, strip: false)
                
                if bookmark == true {
                    self?.mainCoordinator?.totalBookmarks += 1
                }
                else {
                    self?.mainCoordinator?.totalBookmarks -= 1
                }
                
                self?.reloadVisibleCells()
            
            }
            
        }
        
    }
    
}

// MARK: - Context Menus
extension FeedVC {
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) -> UIMenu? in
            
            guard let sself = self else {
                return nil
            }
            
            var read: UIAction!
            var bookmark: UIAction!
            
            if item.read == true {
                
                read = UIAction(title: "Mark Unread", image: UIImage(systemName: "circle"), identifier: nil, handler: { (_) in
                    
                    sself.userMarkedArticle(item, read: false)
                    
                })
                
            }
            else {
                
                read = UIAction(title: "Mark Read", image: UIImage(systemName: "largecircle.fill.circle"), identifier: nil, handler: { (_) in
                    
                    sself.userMarkedArticle(item, read: true)
                    
                })
                
            }
            
            if item.bookmarked == true {
                
                bookmark = UIAction(title: "Unbookmark", image: UIImage(systemName: "bookmark"), identifier: nil, handler: { (_) in
                    
                    sself.userMarkedArticle(item, bookmark: false)
                    
                })
                
            }
            else {
                
                bookmark = UIAction(title: "Bookmark", image: UIImage(systemName: "bookmark.fill"), identifier: nil, handler: { (_) in
                    
                    sself.userMarkedArticle(item, bookmark: true)
                    
                })
                
            }
            
            let browser = UIAction(title: "Open in Browser", image: UIImage(systemName: "safari"), identifier: nil) { [weak item] (_) in
                
                guard let a = item else {
                    return
                }
                
                sself.openInBrowser(a)
                
            }
            
            let share = UIAction(title: "Share Article", image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { (_) in
                
                self?.wantsToShare(item, indexPath: indexPath)
                
            }
            
            if sself.type == .author || sself.type == .bookmarks || sself.type == .folder {
                
                return UIMenu(title: "Article Actions", children: [
                    read,
                    bookmark,
                    browser,
                    share
                ])
                
            }
            
            let directionalNewerImageName = sself.sorting.isAscending ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
            
            let directionalOlderImageName = sself.sorting.isAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
            
            let directionalNewer = UIAction(title: "Mark Newer Read", image: UIImage(systemName: directionalNewerImageName), identifier: nil) { (_) in
                
                self?.markAllNewerRead(indexPath)
                
            }
            
            let directionalOlder = UIAction(title: "Mark Older Read", image: UIImage(systemName: directionalOlderImageName), identifier: nil) { (_) in
                
                self?.markAllOlderRead(indexPath)
                
            }
            
            if sself.type == .natural,
               let author = item.author?.stripHTML(),
               author.isEmpty == false {
                
                let title = "Articles by \(author)"
                
                let authorAction = UIAction(title: title, image: UIImage(systemName: "person.fill"), identifier: nil) { (_) in
                    
                    sself.showAuthorVC(author)
                    
                }
                
                return UIMenu(title: "Article Actions", children: [
                    read,
                    bookmark,
                    browser,
                    share,
                    authorAction,
                    directionalNewer,
                    directionalOlder
                ])
                
            }
            
            return UIMenu(title: "Article Actions", children: [
                read,
                bookmark,
                browser,
                share,
                directionalNewer,
                directionalOlder
            ])
            
        }
        
        return config
        
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        let read = UIContextualAction(style: .normal, title: (item.read ? "Unread" : "Read")) { [weak self, weak item] (_, _, completion) in
            
            guard let sself = self, let sitem = item else {
                return
            }
            
            completion(true)
            
            sself.userMarkedArticle(sitem, read: !sitem.read)
            
        }
        
        read.image = UIImage(systemName: (item.read ? "circle" : "largecircle.fill.circle"))
        read.backgroundColor = .systemBlue
        
        let bookmark = UIContextualAction(style: .normal, title: (item.bookmarked ? "Unbookmark" : "Bookmark")) { [weak self, weak item] (_, _, completion) in
            
            guard let sself = self, let sitem = item else {
                return
            }
            
            completion(true)
            
            sself.userMarkedArticle(sitem, bookmark: !sitem.bookmarked)
            
        }
        
        bookmark.image = UIImage(systemName: (item.read ? "bookmark" : "bookmark.fill"))
        bookmark.backgroundColor = .systemOrange
        
        let c = UISwipeActionsConfiguration(actions: [read, bookmark])
        c.performsFirstActionWithFullSwipe = true
        
        return c
        
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        let browser = UIContextualAction(style: .normal, title: "Browser") { [weak self, weak item] (_, _, completion) in
            
            completion(true)
            
            guard let sself = self , let a = item else {
                return
            }
            
            sself.openInBrowser(a)
            
        }
        
        browser.image = UIImage(systemName: "safari")
        browser.backgroundColor = .systemTeal
        
        let share = UIContextualAction(style: .normal, title: "Share") { [weak self, weak item] (_, _, completion) in
            
            completion(true)
            
            guard let sself = self , let a = item else {
                return
            }
            
            sself.wantsToShare(a, indexPath: indexPath)
            
        }
        
        share.image = UIImage(systemName: "square.and.arrow.up")
        share.backgroundColor = .systemGray
        
        let c = UISwipeActionsConfiguration(actions: [browser, share])
        c.performsFirstActionWithFullSwipe = true
        
        return c
        
    }
    
    func wantsToShare(_ item: Article, indexPath: IndexPath) {
        
        guard Thread.isMainThread == true else {
            
            DispatchQueue.main.async { [weak self] in
                self?.wantsToShare(item, indexPath: indexPath)
            }
            
            return
            
        }
        
        let title = item.title ?? "Untitled"
        
        guard let url = item.url else {
            return
        }
        
        let avc = UIActivityViewController(activityItems: [title, url], applicationActivities: nil)
        
        if let pvc = avc.popoverPresentationController {
            
            pvc.sourceView = tableView
            pvc.sourceRect = tableView.cellForRow(at: indexPath)?.frame ?? .zero
            
        }
        
        present(avc, animated: true, completion: nil)
        
    }
    
    func showAuthorVC(_ author: String) {
        
        guard Thread.isMainThread == true else {
            
            DispatchQueue.main.async { [weak self] in
                self?.showAuthorVC(author)
            }
            
            return
            
        }
        
        guard author.isEmpty == false else {
            return
        }
        
        // @TODO
        
    }
    
    func openInBrowser(_ item: Article) {
        
        var readerMode = false
        
        if (item.read == false) {
            userMarkedArticle(item, read: true)
        }
        
        if type == .natural {
            
            let metadata = DBManager.shared.metadataForFeed(feed!)
            
            readerMode = metadata.readerMode
            
        }
        
        let readerModeString = (readerMode ? "&ytreader=1" : "")
        
        if let url = URL(string: "yeti://external?link=\(item.url!)\(readerModeString)") {
            
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
                
            }
            
        }
        
    }
    
}

extension FeedVC: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        if traitCollection.horizontalSizeClass == .regular {
            return .popover
        }
        
        return .none
        
    }
    
}
