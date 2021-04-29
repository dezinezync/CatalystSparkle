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
import Defaults
import Dynamic

let dbFilteredViewName: String = "feedFilteredView"

//final class FeedItem: Article {}

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

@objc public enum FeedSorting: Int {
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
        
        return FeedVC.imageNameForSortingOption(option: self)
        
    }
    
}

enum MarkDirection: Int {
    case newer = 1
    case older = 2
}

@objcMembers public class FeedVC: UITableViewController {
    
    var type: FeedType = .natural
    @objc var feed: Feed? = nil
    var cancellables: [AnyCancellable] = []
    
    // used for scroll loading
    var allLoaded: Bool = false
    
    #if targetEnvironment(macCatalyst)
    var totalUnread: UInt = 0
    #endif
    
    let feedbackGenerator = UISelectionFeedbackGenerator()
    
    static func imageNameForSortingOption(option: FeedSorting) -> String {
        switch option {
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
    
    var state: FeedVCState = .empty {
        didSet {
            if state != oldValue {
                runOnMainQueueWithoutDeadlocking { [weak self] in
                    guard let self = self else { return }
                    CoalescingQueue.standard.add(self, #selector(FeedVC.setupState))
                }
            }
        }
    }
    
    weak var sortingBarItem: UIBarButtonItem? = nil
   
    var _sorting: FeedSorting! {
        
        didSet {
            if type == .unread {
                if Defaults[.unreadFeedSorting] != _sorting.rawValue {
                    Defaults[.unreadFeedSorting] = _sorting.rawValue
                }
            }
            else {
                if Defaults[.feedSorting] != _sorting.rawValue {
                    Defaults[.feedSorting] = _sorting.rawValue
                }
            }
        }
        
    }
    
    var sorting: FeedSorting {
        
        get {
            
            if _sorting == nil {
                
                if type == .unread {
                    _sorting = FeedSorting(rawValue: Defaults[.unreadFeedSorting])!
                }
                else {
                    _sorting = FeedSorting(rawValue: Defaults[.feedSorting])!
                }
            
            }
            
            return _sorting;
            
        }
        
        set {
            
            guard newValue != sorting else {
                return
            }
            
            _sorting = newValue
            
            DispatchQueue.main.async { [weak self] in
                if let name = self?.sorting.imageName {
                    self?.sortingBarItem?.image = UIImage(systemName: name)
                }
            }
            
            updateFeedSorting()
        }
        
    }
    
    var articles: [Article] = []
    
    static var filteringTag: UInt = 0
    static var sortingTag: String = "2021-04-12 10:47"
    
    var loadOnReady: String?
    
    lazy var DS: ArticlesDatasource = {
       
        var ds = ArticlesDatasource(tableView: tableView) { [weak self] (tableView, indexPath, article) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.identifier, for: indexPath) as! ArticleCell
            
            cell.configure(article, feedType: (self?.type)!)
            
            return cell
            
        }
        
        return ds
        
    }()

    public override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        
        tableView.separatorStyle = .singleLine
        
        tableView.estimatedRowHeight = 105
        tableView.rowHeight = UITableView.automaticDimension
        
        #if targetEnvironment(macCatalyst)
        tableView.separatorInsetReference = .fromCellEdges
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorInset = .init(top: 0, left: 12, bottom: 0, right: 12)
        tableView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        #endif
        
        setupFeed()
        setupData()
        setupNavBar()
        
    }
    
    fileprivate var _hasSetup: Bool = false
    
    public override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if _hasSetup == false {
            _hasSetup = true
            setupState()
            updateFeedSorting()
            
            #if targetEnvironment(macCatalyst)
            setupTitleView()
            #endif
        }
        
        #if !targetEnvironment(macCatalyst)
        guard Defaults[.useToolbar] == true else {
            
            if (navigationController?.isToolbarHidden == false) {
                navigationController?.setToolbarHidden(true, animated: true)
            }
            
            return
        }
        
        toolbarItems = toolbarBarItems()
        navigationController?.setToolbarHidden(false, animated: true)
        #endif
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        self.titleView?.shouldBeVisible = true
        self.titleView?.alpha = 0
        
    }
    
    // MARK: - Setups
    weak var titleView: FeedTitleView?
    
    func setupFeed() {
        
        ArticleCell.register(tableView)
        
        let titleView = FeedTitleView()
        titleView.alpha = 0
        titleView.shouldBeVisible = false
        
        switch type {
        case .natural, .author:
            guard let feed = feed else {
                return
            }
            
            self.title = feed.displayTitle
            
            if (type != .author) {
                
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
                        
                        let count = unread
                        
                        sself.titleView?.countLabel.text = "\(count) Unread\(count == 1 ? "" : "s")"
                        
                    }
                    .store(in: &cancellables)
                
                // article states from authorVC propagated to feedVC
                NotificationCenter.default.publisher(for: .DBManagerDidUpdate)
                    .debounce(for: 0.2, scheduler: DBManager.shared.writeQueue)
                    .filter { $0.userInfo?[notificationsKey] != nil && ($0.userInfo?[notificationsKey]! as? [Notification])?.count ?? 0 > 0  }
                    .sink { [weak self] notification in
                        
                        guard let sself = self,
                              let notifications = notification.userInfo?[notificationsKey] as? [Notification],
                              let ext = DBManager.shared.uiConnection.ext(dbFilteredViewName) as? YapDatabaseFilteredViewConnection,
                              ext.hasChanges(for: notifications) else {
                                return
                              }
                        
                        let keys: Set<String> = Set(sself.articles.map { $0.identifier })
                        
                        guard DBManager.shared.uiConnection.hasMetadataChange(forAnyKeys: keys, inCollection: CollectionNames.articles.rawValue, in: notifications) else {
                            return
                        }
                        
                        var itemsToUpdate: [String] = []
                        
                        if let set = (notifications[0].userInfo!["metadataChanges"] as? YapSet) {
                            
                            set.enumerateObjects { i, stop in
                                
                                if let ck = i as? YapCollectionKey,
                                   ck.collection == CollectionNames.articles.rawValue {
                                    
                                    #if DEBUG
                                    print("articles:\(ck.key) updated.")
                                    #endif
                                    
                                    itemsToUpdate.append(ck.key)
                                    
                                }
                                
                            }
                            
                        }
                        
                        guard itemsToUpdate.count > 0 else {
                            return
                        }
                        
                        var articlesToUpdate: [Article] = []
                        
                        // update our local state with the state from the DB.
                        DBManager.shared.uiConnection.read { t in
                            
                            for key in itemsToUpdate {
                                
                                if let metadata: ArticleMeta = t.metadata(forKey: key, inCollection: CollectionNames.articles.rawValue) as? ArticleMeta,
                                   let article:Article = sself.articles.first(where: { $0.identifier == key }) {
                                    
                                    article.read = metadata.read
                                    article.bookmarked = metadata.bookmarked
                                    
                                    articlesToUpdate.append(article)
                                    
                                }
                                
                            }
                            
                        }
                        
                        guard articlesToUpdate.count > 0 else {
                            return
                        }
                        
                        // tell the snapshot to update the cells
                        var snapshot = sself.DS.snapshot()
                        snapshot.reloadItems(articlesToUpdate)
                        
                        DispatchQueue.main.async {
                            sself.DS.apply(snapshot, animatingDifferences: false, completion: nil)
                        }
                        
                    }
                    .store(in: &cancellables)
                
            }
            
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
        
        case .unread:
            self.title = "Unread"
            titleView.titleLabel.text = self.title;
            titleView.faviconView.isHidden = true
            
            if let coordinator = coordinator {
                
                coordinator.$totalUnread
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] count in
                        
                        guard let sself = self else {
                            return
                        }
                        
                        sself.titleView?.countLabel.text = "\(count) Unread\(count == 1 ? "" : "s")"
                        
                    }
                    .store(in: &cancellables)
                
            }
        
        case .today:
            self.title = "Today"
            titleView.titleLabel.text = self.title;
            titleView.faviconView.isHidden = true
            
            if let coordinator = coordinator {
                
                coordinator.$totalToday
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] count in
                        
                        guard let sself = self else {
                            return
                        }
                        
                        sself.titleView?.countLabel.text = "\(count) Unread\(count == 1 ? "" : "s")"
                        
                    }
                    .store(in: &cancellables)
                
            }
            
        default:
            break
        }
        
        navigationItem.titleView = titleView
        self.titleView = titleView
        
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTitleView)))
        
    }
    
    func setupNavBar() {
        
        #if targetEnvironment(macCatalyst)
        navigationController?.navigationBar.isHidden = true
        #else
        
        extendedLayoutIncludesOpaqueBars = true
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic;
        
        if Defaults[.useToolbar] == false {
            navigationItem.rightBarButtonItems = self.rightBarButtonItems()
        }
        
        #endif
        
    }
    
    var dbFilteredView: YapDatabaseFilteredView!
    
    var dbAutoViewName: String {
        
        let sortingKey: Int = self.sorting.isAscending == true ? 1 : 2;
        
        var feedKey: String!
        
        switch type {
        case .unread:
            feedKey = "unread"
        case .today:
            feedKey = "today"
        case .bookmarks:
            feedKey = "bookmarks"
        case .natural:
            feedKey = "feed:\(feed!.feedID!)"
        default:
            feedKey = ""
        }
        
        return "feedFilteredView::\(feedKey!)::\(sortingKey)"
        
    }
    
    func updateFeedSorting() {
        
        let sortingOption = self.sorting
        
        if let _ = DBManager.shared.bgConnection.ext(dbAutoViewName) as? YapDatabaseAutoViewConnection {
            // not required. already setup.
            DispatchQueue.main.async { [weak self] in
                self?._didSetSortingOption()
            }
            
            return
        }
        
        DBManager.shared.writeQueue.async { [weak self] in
            
            let sortingClosure = YapDatabaseViewSorting.withMetadataBlock { (t, g, c1, k1, m1, c2, k2, m2) -> ComparisonResult in
                
                guard let a1 = m1 as? ArticleMeta, let a2 = m2 as? ArticleMeta else {
                    return .orderedSame
                }

                var result: ComparisonResult = a1.timestamp.compare(other: a2.timestamp)
                
                if result == .orderedSame {
                    
                    // compare against IDs
                    result = k1.compare(k2)
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
                
                let grouping = YapDatabaseViewGrouping.withKeyBlock { (t, col, key) -> String? in
                    
                    if col == CollectionNames.articles.rawValue {
                        return GroupNames.articles.rawValue
                    }
                    
                    return nil
                    
                }
                
                let options: YapDatabaseViewOptions = YapDatabaseViewOptions()
                options.isPersistent = true
                
                let newView: YapDatabaseAutoView = YapDatabaseAutoView(grouping: grouping, sorting: sortingClosure, versionTag: FeedVC.sortingTag, options: options)
                
                DBManager.shared.database.asyncRegister(newView, withName: sself.dbAutoViewName) { completed in
                    
                    DispatchQueue.main.async {
                        sself._didSetSortingOption()
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func setupViews() {
        
        let baseViewName = dbAutoViewName
        
        let filters: [String] = DBManager.shared.user?.filters ?? []
        let filtersSet: Set<String> = Set(filters)
        
        let filtering = YapDatabaseViewFiltering.withMetadataBlock { [weak self] (t, g, c, k, m) -> Bool in
            
            guard let sself = self else {
                return false
            }
            
            guard let metadata = m as? ArticleMeta else {
                return false
            }
            
            if sself.type == .natural || sself.type == .author {
                
                guard let feed = sself.feed else {
                    return false
                }
                
                let feedID = feed.feedID
                
                guard metadata.feedID == feedID else {
                    return false
                }
                
            }
            else if sself.type == .today {
                
                if Calendar.current.isDateInToday(Date(timeIntervalSince1970: metadata.timestamp)) == false {
                    return false
                }
                
            }
            
            // Filters of the user
            if filters.count > 0 {
                
                // compare the title to each item in the filters
                let wordCloud = metadata.titleWordCloud ?? []
                
                let set1 = Set(wordCloud)
                
                let intersects = set1.intersection(filtersSet).count == 0
                
                guard intersects == true else {
                    return false
                }
                
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
    
    #if targetEnvironment(macCatalyst)
    public func setupTitleView() {
        
        guard let title: String = self.title else {
            return
        }
        
        guard let window = coordinator?.innerWindow else {
            return
        }
        
        Dynamic(window).title = title
        
        var publisher: Published<UInt>.Publisher!
        
        switch type {
        case .natural:
            publisher = feed!.$unread
        case .unread:
            publisher = coordinator!.$totalUnread
        case .today:
            publisher = coordinator!.$totalToday
        default: break
            
        }
        
        if publisher != nil {
            
            publisher!
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
        
    }
    #endif
    
    func setupState() {
        
        // if the state is empty and there are no articles,
        // there is nothing to be done.
        guard state != .empty else {
            
            if total == -1 {
                showLoadingState()
            }
            else {
                showEmptyState()
            }
            
            return
        }
        
        removeEmptyState()
        
        if total == -1 || (state == .loading && articles.count == 0) {
            showLoadingState()
            return
        }
        
        if state == .errored, articles.count == 0 {
            // @TODO: Show error state
            return
        }
        
        if activityIndicator.isAnimating == true {
            activityIndicator.stopAnimating()
        }
        
        if state == .loaded, total == 0 {
            showEmptyState()
        }
        
    }
    
    func setupData() {
        
        runOnMainQueueWithoutDeadlocking { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            let isEmpty = sself.DS.snapshot().numberOfItems == 0
            let animated = isEmpty == true ? false : (sself.view.window != nil)
            
            var snapshot = NSDiffableDataSourceSnapshot<Int, Article>()
            snapshot.appendSections([0])
            snapshot.appendItems(sself.articles)
            
            sself.DS.apply(snapshot, animatingDifferences: animated, completion: nil)
            
        }
        
    }
    
    fileprivate var total: Int = -1
    fileprivate var currentPage: UInt = 0
    fileprivate var _loadNextRetries: UInt = 0
    
    func _didSetSortingOption() {
        
        articles = []
        state = .empty
        
        total = -1
        currentPage = 0
        _loadNextRetries = 0
        
        setupData()
        setupState()
        
        setupViews()
        
    }
    
    // MARK: - Updates
    var isShowingEmptyState: Bool = false
    
    var _emptyView: UIView?
    
    var emptyViewDisplayTitle: String {
        return feed!.displayTitle
    }
    
    func emptyView () -> UIView {
        
        let titleText = sorting.isUnread ? "No unread articles" : "No recent articles"
       
        let title = UILabel()
        title.font = .preferredFont(forTextStyle: .headline)
        title.textColor = .secondaryLabel
        title.text = titleText.capitalized(with: Locale.current)
        title.numberOfLines = 0
        title.textAlignment = .center
        
        let subtitle = UILabel()
        #if targetEnvironment(macCatalyst)
        subtitle.font = .preferredFont(forTextStyle: .body)
        #else
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        #endif
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        
        subtitle.text = "\(titleText) in \(emptyViewDisplayTitle)."
        
        if sorting.isUnread == true {
            subtitle.text = "\(subtitle.text!) You're all caught up."
        }
        
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        stack.axis = .vertical
        stack.isBaselineRelativeArrangement = true
        
        #if !targetEnvironment(macCatalyst)
        
        let widthConstraint = stack.widthAnchor.constraint(lessThanOrEqualToConstant: 351)
        widthConstraint.priority = UILayoutPriority(rawValue: 999)
        widthConstraint.isActive = true
        
        #endif
        
        return stack
        
    }
    
    func showEmptyState () {
        
        guard isShowingEmptyState == false else {
            return
        }
        
        if _emptyView != nil {
            removeEmptyState()
        }
        
        let ev = emptyView()
        ev.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(ev)
        
        #if targetEnvironment(macCatalyst)
        let leadingConstraint = ev.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 12)
        leadingConstraint.priority = UILayoutPriority(rawValue: 999)
        
        let trailingConstraint = ev.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: 12)
        trailingConstraint.priority = UILayoutPriority(rawValue: 999)
        
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint])
        #endif
        
        _emptyView = ev
        isShowingEmptyState = true
        
        NSLayoutConstraint.activate([
            ev.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            ev.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
    }
    
    func removeEmptyState() {
        
        guard isShowingEmptyState == true else {
            return
        }
        
        guard let view = _emptyView else {
            return
        }
        
        view.removeFromSuperview()
        _emptyView = nil
        
        isShowingEmptyState = false
        
    }
    
    lazy var activityIndicator = UIActivityIndicatorView(style: .medium)
    
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
    
    public func toolbarBarItems() -> [UIBarButtonItem]? {
        
        guard Defaults[.useToolbar] == true else {
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
    
    // Necessary to work around a `UIScrollView` behavior difference on Mac. See `scrollViewDidScroll`
    // and `preventOverscrollIfNeeded` for more context.
    private lazy var isRunningOnMac: Bool = {
        if #available(iOS 13.0, *) {
            if ProcessInfo.processInfo.isMacCatalystApp {
                return true
            }
        }

        return false
    }()

}

extension FeedVC: ScrollLoading {
    
    public func isLoading() -> Bool {
        return state.isLoading
    }
    
    public func canLoadNext() -> Bool {
        
        if allLoaded == true {
            return false
        }
        
        return total == -1 || articles.count < total
        
    }
    
    public func loadNextPage() {
        
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
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
            
            guard sself.total > 0 else {
                sself.state = .loaded
                return
            }
            
            let page = sself.currentPage + 1
            
            var rangeLength: Int = 20
            
            if (rangeLength > total) {
                rangeLength = total
            }
            else if ((rangeLength * Int(page)) > total) {
                rangeLength = total - articles.count
            }
            
            var range = NSMakeRange(((Int(page) - 1) * 20) - 1, rangeLength)
            
            if page == 1 {
                range.location = 0
            }
            
            var context: UInt = 0
            
            txn.enumerateRows(inGroup: group, with: [], range: range) { (a, b) -> Bool in
                return true
            } using: { (c, k, o, m, index, stop) in
                
                guard let article = o as? Article,
                      let metadata = m as? ArticleMeta else {
                    return
                }
                
                article.read = metadata.read
                article.bookmarked = metadata.bookmarked
                article.fulltext = metadata.fulltext
                
                if article.title == nil || (article.title != nil && article.title!.isEmpty == true) {
                    // get the content, possibly micro.blog post
                    if let ft = DBManager.shared.fullText(for: article.identifier) {
                        article.content = ft
                        article.fulltext = true
                    }
                    else if let c = DBManager.shared.content(for: article.identifier) {
                        article.content = c
                        article.fulltext = false
                    }
                }
                
                sself.articles.append(article)
                context += 1
                
            }
            
            sself.currentPage = page
            
            if context < 20 {
                // we expected 20. so check.
                allLoaded = true
                
//                if sself.articles.count != sself.total {
//
//                    // some articles could not be fetched.
//                    // so lets correct our total
//                    sself.total -= (20 - Int(context))
//
//                }
                
            }
            
            sself.state = .loaded
            
            if context > 0 {
                sself.setupData()
            }

        }
        
    }
    
}

// MARK: - Overscrolling Bug

/**
 * There is an overscrolling bug on macOS which causes the FeedVC to behave oddly.
 * Luckily, this issue has been experienced by others and a fix (hack/workaround)
 * is available: https://github.com/airbnb/HorizonCalendar/pull/91
 *
 * Source: https://github.com/airbnb/HorizonCalendar/pull/91/commits/2e9826cf5bd58d13d66c61855195beed9e7c6f19
 */
extension FeedVC {
    
    @objc public func dz_scrollViewDidScroll(_ scrollView: UIScrollView!) {
        
//        print("isOverscrolling: \(isOverscrolling)")
        
        #if !targetEnvironment(macCatalyst)
        
        if let navBar = navigationController?.navigationBar {
          
            let height = navBar.frame.height
            let maxY: CGFloat = 68
            let minY: CGFloat = 44
            
            // large title
            if height > minY {
                
                // for a height of greater than 60, the large title is still visible
                if height > maxY, titleView?.alpha != 0 {
                    titleView?.alpha = 0
                }
                
                if height < maxY {
                    // extrapolate the opacity in 0.0 - 1.0 for height range 44 - 60
                    // 44:1 :: 60 : 0
                    let alpha = 1 - ((height - minY)/(maxY - minY))
                    titleView?.alpha = alpha
                }
                
            }
            
        }
        
        #endif
        
        preventLargeOverscrollIfNeeded()
        
    }
    
    public var isOverscrolling: Bool {
        
        let scrollAxis: ScrollAxis = .vertical
        
        let offset = tableView.offset(for: scrollAxis)
        
        return offset < tableView.minimumOffset(for: scrollAxis) ||
                offset > tableView.maximumOffset(for: scrollAxis)
        
    }
    
    // This hack is needed to prevent the scroll view from overscrolling far past the content. This
     // occurs in 2 scenarios:
     // - On macOS if you scroll quickly toward a boundary
     // - On iOS if you scroll quickly toward a boundary and targetContentOffset is mutated
     //
     // https://openradar.appspot.com/radar?id=4966130615582720 demonstrates this issue on macOS.
    private func preventLargeOverscrollIfNeeded() {
        
        guard isRunningOnMac == true else { return }
        
        let isUserInitiatedScrolling = tableView.isDragging && tableView.isTracking
        
        guard isUserInitiatedScrolling == true else { return }
        
        let scrollAxis: ScrollAxis = .vertical
        
        let offset = tableView.offset(for: scrollAxis)
        
        let boundsSize: CGFloat
        switch scrollAxis {
        case .vertical: boundsSize = tableView.bounds.height * 0.7
        case .horizontal: boundsSize = tableView.bounds.width * 0.7
        }
        print(boundsSize)
        let newOffset: CGPoint?
        if offset < tableView.minimumOffset(for: scrollAxis) - boundsSize {
            switch scrollAxis {
            case .vertical:
                newOffset = CGPoint(
                    x: tableView.contentOffset.x,
                    y: tableView.minimumOffset(for: scrollAxis))
                
            case .horizontal:
                newOffset = CGPoint(
                    x: tableView.minimumOffset(for: scrollAxis),
                    y: tableView.contentOffset.y)
            }
        }
        else if offset > tableView.maximumOffset(for: scrollAxis) + boundsSize {
            switch scrollAxis {
            case .vertical:
                newOffset = CGPoint(
                    x: tableView.contentOffset.x,
                    y: tableView.maximumOffset(for: scrollAxis))
                
            case .horizontal:
                newOffset = CGPoint(
                    x: tableView.maximumOffset(for: scrollAxis),
                    y: tableView.contentOffset.y)
            }
        } else {
            newOffset = nil
        }
        
        #if DEBUG
        print("newoffset: \(newOffset)")
        #endif
        
        if let newOffset = newOffset {
            tableView.performWithoutNotifyingDelegate {
                // Passing `false` for `animated` is necessary to stop the in-flight deceleration animation
                UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                    self.tableView.setContentOffset(newOffset, animated: false)
                })
            }
        }
        
    }
    
}

// MARK: - Actions
extension FeedVC {
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return
        }
        
        setupArticle(item)
        
    }
    
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
        
        Haptics.shared.generate(feedbackType: .selectionChange)
        
        DBManager.shared.readQueue.async { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            var items: [String: Article] = [:]
            
            DBManager.shared.bgConnection.readWrite { [weak self] (t) in
                
                guard let txn = t.ext(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                    return
                }
                
                let count = txn.numberOfItems(inGroup: GroupNames.articles.rawValue)
                
                guard count > 0 else {
                    
                    if  self?.type == .natural, let feed = self?.feed, feed.unread > 0 {
                        feed.unread = 0
                    }
                    
                    return
                }
                
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
                    
                }
                
            }
            
            guard items.count > 0 else {
                print("No items to be marked read. Exiting.")
                return
            }
            
            print("Marking \(items.count) items as read")
            
            sself.markRead(items) { [weak self] completed in
                
                if completed == true {
                    DispatchQueue.global().async {
                        self?.articles.forEach { $0.read = true }
                    }
                }
                
            }
            
        }
        
    }
    
    func markRead(_ inItems: [String: Article], completion:((_ completed: Bool) -> Void)?) {
        
        let items = inItems
        
        FeedsManager.shared.markRead(true, items: items.values.map { $0 }) { (result) in
            
            switch result {
            
            case .failure(let err):
                
                let error = (err as NSError)
                
                AlertManager.showAlert(title: "An Error Occurred", message: error.localizedDescription, confirm: nil, cancel: "Okay")
                
                DispatchQueue.main.async {
                    
                    completion?(false)
                    
                }
                
                return
                
            case .success(let results):
                
                // get all successful items
                let succeeded = results
                    .filter { $0.status == true }
                    .map { String($0.articleID) }
                
                let successItems = items.filter({ (elem) -> Bool in
                    
                    return succeeded.contains(elem.key)
                    
                })
                
                // if the items count is 0, then the articles were already marked as read.
                // we don't have that record on disk. This silently fails on the server and
                // returns a succees response. We must do the same here as well.
                if successItems.count > 0 {
                    for i in successItems { i.value.read = true }
                    DBManager.shared.add(articles: Array(successItems.values), strip: false)
                }
                else {
                    for i in items { i.value.read = true }
                    DBManager.shared.add(articles: Array(items.values), strip: false)
                }
                
                DBManager.shared.add(articles: items.values.map { $0 }, strip: false)
                
                DispatchQueue.main.async {
                    
                    completion?(true)
                    
                }
            
            }
            
        }
        
    }
    
    @objc func didTapBack() {
        
        navigationController?.popToRootViewController(animated: true)
        
    }
    
    @objc func didTapTitleView() {
        
        guard type == .natural,
              let feed = self.feed,
              let coordinator = coordinator else {
            return
        }
        
        coordinator.showFeedInfo(feed: feed, from: self, completion: nil)
        
    }
    
    @objc func markAllNewerRead(_ indexPath: IndexPath) {
        
        markDirectional(.newer, indexPath: indexPath)
        
    }
    
    @objc func markAllOlderRead(_ indexPath: IndexPath) {
        
        markDirectional(.older, indexPath: indexPath)
        
    }
    
    func markDirectional(_ direction: MarkDirection, indexPath: IndexPath) {
        
        let sorting = self.sorting
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return
        }
        
        var isDescending = sorting.isAscending == false
        isDescending = (direction == .newer && isDescending) || (direction == .older && isDescending == false)
        
        let options: NSEnumerationOptions = isDescending == false ? .reverse : []
        
        // our unreads array count can't exceed this so we
        // can use this as a control to stop enumerating.
        let grandTotal = coordinator?.totalUnread ?? 0
        
        DBManager.shared.uiConnection.asyncRead { [weak self] (t) in
            
            guard let txn = t.ext(dbFilteredViewName) as? YapDatabaseFilteredViewTransaction else {
                return
            }
            
            guard let sself = self else {
                return
            }
            
            let localIdentifier = item.identifier!
            let localID = (localIdentifier as NSString).integerValue
            
            let localTimestamp = item.timestamp.timeIntervalSince1970
            
            let total = Int(txn.numberOfItems(inGroup: GroupNames.articles.rawValue))
        
            var unreads: [String: Article] = [:]
            
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
                    
                }
                
                if grandTotal == unreads.count {
                    stop.pointee = true
                }
                
            }
            
            guard unreads.count > 0 else {
                return
            }
            
            let unreadKeys = unreads.map { $0.key };
            
            #if DEBUG
            print("IDs: ", unreadKeys)
            #endif
            
            sself.markRead(unreads) { completed in
                
                if completed == true {
                    
                    var toUpdate: [Article] = []
                    
                    for key in unreadKeys {
                        
                        if let a: Article = sself.articles.first(where: { $0.identifier == key }) {
                            
                            a.read = true
                            
                            toUpdate.append(a)
                            
                        }
                        
                    }
                    
                    DBManager.shared.add(articles: toUpdate, strip: false)
                    
                }
                
            }
            
        }
        
    }
    
}

extension FeedVC: BarPositioning {
    
    public func rightBarButtonItems() -> [UIBarButtonItem]? {
        
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
    
}

// MARK: - Article Provider
extension FeedVC: ArticleHandler, ArticleProvider {
    
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
            
            setupArticle(a)
            
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
    
    public func setupArticle(_ article: Any) {
        
        guard let a = article as? Article else {
            return
        }
        
        coordinator?.showArticle(a)
        
    }
    
    public func currentArticle() -> Any? {
        
        guard let selected = tableView.indexPathForSelectedRow else {
            return nil
        }
        
        return DS.itemIdentifier(for: selected)
        
    }
    
    @objc public func userMarkedArticle(_ article: Any, read: Bool) {
        userMarkedArticle(article, read: read, completion: nil)
    }
        
    @objc public func userMarkedArticle(_ article: Any, read: Bool, completion: ((_ completed: Bool) -> Void)?) {
        
        guard let article = article as? Article else {
            return
        }
        
        FeedsManager.shared.markRead(read, items: [article]) { [weak self] (result) in
            
            guard let sself = self,
                  let coordinator = sself.coordinator else {
                return
            }
            
            switch result {
            case .failure(let error):
                AlertManager.showGenericAlert(withTitle: "Error Marking \(read ? "Read" : "Unread")", message: error.localizedDescription)
                completion?(false)
                
            case .success(_):
                
                article.read = read
                
                DBManager.shared.add(article: article, strip: false)
                
                let inToday = Calendar.current.isDateInToday(article.timestamp)
                
                let feed = DBManager.shared.feedForID(article.feedID)
                
                if read == true {
                    
                    var read = coordinator.totalUnread
                    
                    if read == 0 { read = 1 }
                    
                    coordinator.totalUnread = max(read - 1, 0)
                    
                    if inToday {
                        
                        var today = coordinator.totalToday
                        
                        if today == 0 { today = 1 }
                        
                        coordinator.totalToday = max(today - 1, 0)
                        
                    }
                    
                    var unread = feed?.unread ?? 1
                    
                    if unread == 0 { unread = 1 }
                    
                    feed?.unread = max(unread - 1, 0)
                    
                }
                else {
                    
                    self?.coordinator?.totalUnread += 1
                    
                    if inToday { self?.coordinator?.totalToday += 1 }
                    
                    feed?.unread += 1
                    
                }
                
                completion?(true)
                
            }
            
        }
        
    }
    
    @objc public func userMarkedArticle(_ article: Any, bookmarked: Bool) {
        userMarkedArticle(article, bookmarked: bookmarked, completion: nil)
    }
    
    @objc public func userMarkedArticle(_ article: Any, bookmarked: Bool, completion: ((_ completed: Bool) -> Void)?) {
        
        guard let article = article as? Article else {
            return
        }
        
        FeedsManager.shared.mark(bookmarked, item: article) { [weak self] (result) in
            
            switch result {
            
            case .failure(let error):
                AlertManager.showGenericAlert(withTitle: "Error \(bookmarked ? "Bookmark" : "Unbookmark")ing", message: error.localizedDescription)
                completion?(false)
            
            case .success(let result):
                
                guard result.status == true else {
                    
                    AlertManager.showGenericAlert(withTitle: "Error \(bookmarked ? "Bookmark" : "Unbookmark")ing", message: "An unknown error occurred when performing this action.")
                    
                    completion?(false)
                    
                    return
                    
                }
                
                article.bookmarked = bookmarked
                DBManager.shared.add(article: article, strip: false)
                
                if bookmarked == true {
                    self?.coordinator?.totalBookmarks += 1
                }
                else {
                    self?.coordinator?.totalBookmarks -= 1
                }
                
                completion?(true)
            
            }
            
        }
        
    }
    
    public func hasPreviousArticle(forArticle item: Any) -> Bool {
        
        guard let item = item as? Article else {
            return false
        }
        
        guard let indexPath = DS.indexPath(for: item) else {
            return false
        }
        
        return indexPath.row > 0 && DS.snapshot().numberOfItems >= 2
        
    }
    
    public func hasNextArticle(forArticle item: Any) -> Bool {
        
        guard let item = item as? Article else {
            return false
        }
        
        guard let indexPath = DS.indexPath(for: item) else {
            return false
        }
        
        let lastIndex = DS.snapshot().numberOfItems - 1
        
        guard indexPath.row != lastIndex else {
            return false
        }
        
        return lastIndex >= 1
        
    }
    
    public func previousArticle(for item: Any) -> Any? {
        
        guard let item = item as? Article else {
            return nil
        }
        
        guard let indexPath = DS.indexPath(for: item) else {
            return nil
        }
        
        guard indexPath.row > 0 else {
            return nil
        }
        
        let prevIndexPath = IndexPath(row: max(0, indexPath.row - 1), section: indexPath.section)
        
        let prevItem = DS.itemIdentifier(for: prevIndexPath)
        
        if prevItem != nil { willChangeArticle() }
        
        return prevItem
        
    }
    
    public func nextArticle(for item: Any) -> Any? {
        
        guard let item = item as? Article else {
            return nil
        }
        
        guard let indexPath = DS.indexPath(for: item) else {
            return nil
        }
        
        let max = DS.snapshot().numberOfItems
        
        guard indexPath.row < max else {
            return nil
        }
        
        let nextIndexPath = IndexPath(row: min(max - 1, indexPath.row + 1), section: indexPath.section)
        
        let nextItem = DS.itemIdentifier(for: nextIndexPath)
        
        if nextItem != nil { willChangeArticle() }
        
        return nextItem
        
    }
    
    func willChangeArticle() {
        
        Haptics.shared.generate(feedbackType: .selectionChange)
        
    }
    
    public func didChange(toArticle item: Any) {
        
        guard let item = item as? Article else {
            return
        }
        
        guard let indexPath = DS.indexPath(for: item) else {
            return
        }
        
        if type == .natural && item.read == false {
            userMarkedArticle(item, read: true)
        }
        
        dispatchMainAsync { [weak self] in
            self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        }
        
        /**
         * Say there are 20 objects in our DataStore
         * Our index is at 14 (0-based)
         * We're expecting the equation below to result 6 (20-14)
         * Which actually would state that 5 articles are remaining.
         */
        let loadNextPage = (DS.snapshot().numberOfItems - indexPath.row) < 6
        
        if loadNextPage {
            
            dispatchMainAsync { [weak self] in
                
                guard let sself = self else {
                    return
                }
                
                if sself.responds(to: #selector(sself.self.scrollViewDidScroll(_:))) == true  {
                    
                    sself.scrollViewDidScroll(sself.tableView)
                    
                }
                
            }
            
        }
        
    }
    
    #if targetEnvironment(macCatalyst)
    public override func responds(to aSelector: Selector!) -> Bool {
        
        let str = NSStringFromSelector(aSelector)

        if str == "didTapMarkAll:" {
            // conditionally enable or disable the mark all button.
            // if we don't have any unread articles, let's return
            // no from here.
            return totalUnread > 0
        }
        
        return super.responds(to: aSelector)
        
    }
    #endif
    
}

// MARK: - Context Menus
extension FeedVC {
    
    public override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
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
                    
                    sself.userMarkedArticle(item, bookmarked: false)
                    
                })
                
            }
            else {
                
                bookmark = UIAction(title: "Bookmark", image: UIImage(systemName: "bookmark.fill"), identifier: nil, handler: { (_) in
                    
                    sself.userMarkedArticle(item, bookmarked: true)
                    
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
    
    public override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
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
            
            sself.userMarkedArticle(sitem, bookmarked: !sitem.bookmarked)
            
        }
        
        bookmark.image = UIImage(systemName: (item.read ? "bookmark" : "bookmark.fill"))
        bookmark.backgroundColor = .systemOrange
        
        let c = UISwipeActionsConfiguration(actions: [read, bookmark])
        c.performsFirstActionWithFullSwipe = true
        
        return c
        
    }
    
    public override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
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
        
        coordinator?.showAuthorVC(feed!, author: author)
        
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
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        if traitCollection.horizontalSizeClass == .regular {
            return .popover
        }
        
        return .none
        
    }
    
}
