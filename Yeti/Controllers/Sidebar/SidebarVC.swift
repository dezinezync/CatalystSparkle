//
//  SidebarVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 11/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import UIKit
import DBManager
import Models
import Combine
import Networking
import YapDatabase
import Defaults
import StoreKit

class SidebarDS: UICollectionViewDiffableDataSource<Int, SidebarItem> {
       
}

@objc enum FeedType: Int {
    case natural
    case unread
    case today
    case bookmarks
    case folder
    case author
}

@objcMembers public class CustomFeed: NSObject {
    
    let title: String
    let image: UIImage?
    let color: UIColor
    let feedType: FeedType
    
    required init(title: String, image: String, color: UIColor?, type: FeedType) {
        
        self.title = title
        self.image = UIImage(systemName: image)
        self.feedType = type
        self.color = color ?? .systemBlue
        
    }
    
    public override var hash: Int {
        return title.hash + feedType.rawValue
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        
        guard let rhs = object as? CustomFeed else {
            return false
        }
        
        return self.title == rhs.title || self.feedType == rhs.feedType
        
    }
    
}

enum SidebarSection: Int, CaseIterable {
    
    case custom
    case folders
    case feeds
    
}

enum SidebarItem: Hashable, Identifiable {
    
    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        
        switch (lhs, rhs) {
        case (.feed(let f1), .feed(let f2)):
            return f1.feedID == f2.feedID
        case (.folder(let f1), .folder(let f2)):
            return f1.folderID == f2.folderID
        case (.custom(let f1), .custom(let f2)):
            return f1.title == f2.title
        default:
            return false
        }
        
    }
    
    case custom(CustomFeed)
    case folder(Folder)
    case feed(Feed)
    
    func hash(into hasher: inout Hasher) {
        
        switch self {
        case .custom(let f):
            hasher.combine(f.feedType)
        case .feed(let f):
            hasher.combine(f.feedID)
        case .folder(let f):
            hasher.combine(f.folderID)
        }
        
    }
    
    var id: Int {
        get {
            switch self {
            case .custom(let f):
                return f.feedType.rawValue
            case .feed(let f):
                return Int(f.feedID)
            case .folder(let f):
                return Int(f.folderID)
            }
        }
    }
    
}

@objcMembers public class SidebarVC: UICollectionViewController {
    
    var cancellables: [AnyCancellable] = []
    
    // Rename Feed Variables
    weak var alertDoneAction: UIAlertAction?
    weak var alertTextField: UITextField?
    weak var alertFeed: Feed?
    
    let coalescingQueue: CoalescingQueue = CoalescingQueue(name: "SidebarCoalescingQueue", interval: 0.25, maxInterval: 1)
    
    lazy var layout: UICollectionViewCompositionalLayout = {
       
        var l = UICollectionViewCompositionalLayout { (section, environment) -> NSCollectionLayoutSection? in
            
            let appearance: UICollectionLayoutListConfiguration.Appearance = environment.traitCollection.userInterfaceIdiom == .phone ? .plain : .sidebar
            
            var config = UICollectionLayoutListConfiguration(appearance: appearance)
            config.showsSeparators = false
            
            if section == SidebarSection.custom.rawValue {
//                #if targetEnvironment(macCatalyst)
//                config.headerMode = .supplementary
//                #endif
                
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            }
            
            if section == SidebarSection.folders.rawValue {
                // this is only applicable for feeds with folders
                config.headerMode = .firstItemInSection
            }
            
            config.trailingSwipeActionsConfigurationProvider = { [weak self] (indexPath) -> UISwipeActionsConfiguration? in
                
                guard let sself = self else { return nil }
                
                guard let item = sself.DS.itemIdentifier(for: indexPath) else { return nil }
                
                var swipeConfig: UISwipeActionsConfiguration? = nil
                
                if case SidebarItem.feed(let feed) = item {
                    
                    let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self, weak feed] (a, sourceView, completionHandler) in
                        
                        guard let sself = self, let sfeed = feed else {
                            return
                        }
                        
                        sself.delete(feed: sfeed, indexPath: indexPath, completion: completionHandler)
                        
                    }
                    
                    let move = UIContextualAction(style: .normal, title: "Move") { [weak self, weak feed] (a, sourceView, completionHandler) in
                        
                        guard let sself = self, let sfeed = feed else {
                            return
                        }
                        
                        sself.move(feed: sfeed, indexPath: indexPath, completion: completionHandler)
                        
                    }
                    
                    move.backgroundColor = .systemBlue
                    
                    let share = UIContextualAction(style: .normal, title: "Share") { [weak self, weak feed] (a, sourceView, completionHandler) in
                        
                        guard let sself = self, let sfeed = feed else {
                            return
                        }
                        
                        sself.shareFeedURL(sfeed, indexPath: indexPath, completion: completionHandler)
                        
                    }
                    
                    share.backgroundColor = .systemGreen
                    
                    swipeConfig = UISwipeActionsConfiguration(actions: [delete, move, share])
                    
                }
                else if case SidebarItem.folder(let folder) = item {
                 
                    let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self, weak folder] (a, sourceView, completionHandler) in
                        
                        guard let sself = self, let sfolder = folder else {
                            return
                        }
                        
                        sself.delete(folder: sfolder, indexPath: indexPath, completion: completionHandler)
                        
                        completionHandler(true)
                        
                    }
                    
                    let rename = UIContextualAction(style: .normal, title: "Rename") { [weak self, weak folder] (a, sourceView, completionHandler) in

                        guard let sself = self, let sfolder = folder else {
                            return
                        }

                        sself.rename(folder: sfolder, indexPath: indexPath)
                        
                        completionHandler(true)

                    }

                    rename.backgroundColor = .systemBlue
                    
                    swipeConfig = UISwipeActionsConfiguration(actions: [delete, rename])
                    
                }
                
                swipeConfig?.performsFirstActionWithFullSwipe = true
                
                return swipeConfig
                
            }
            
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            
        }
        
        return l
        
    }()
    
    fileprivate lazy var DS: SidebarDS = {
        
        let ds = SidebarDS(collectionView: collectionView) { [weak self] (cv, indexPath, item: SidebarItem) -> UICollectionViewCell? in
            
            guard let sself = self else {
                return nil
            }
            
            if case .custom(_) = item {
                return cv.dequeueConfiguredReusableCell(using: sself.customFeedRegistration, for: indexPath, item: item)
            }
            else if case .feed(_) = item {
                return cv.dequeueConfiguredReusableCell(using: sself.feedRegistration, for: indexPath, item: item)
            }
            else if case .folder(_) = item {
                return cv.dequeueConfiguredReusableCell(using: sself.folderRegistration, for: indexPath, item: item)
            }
            
            return nil
            
        }
        
        return ds
        
    }()
    
    fileprivate var initialSyncCompleted = false
    
    public var requiresUpdatingUnreadsSharedData = false {
        
        didSet {
            if requiresUpdatingUnreadsSharedData == true {
                coalescingQueue.add(self, #selector(SidebarVC.updateSharedUnreadsData))
            }
        }
        
    }
    
    init() {
        super.init(collectionViewLayout: UICollectionViewLayout())
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
        
        collectionView.setCollectionViewLayout(layout, animated: false)
        
        title = "Feeds"
        
        if traitCollection.userInterfaceIdiom == .phone {
            collectionView.backgroundColor = .systemBackground
        }
        
        #if targetEnvironment(macCatalyst)
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
        
        scheduleTimerIfValid()
        
        #endif
        
        setupNavigationBar()
        setupCollectionView()
        setupNotifications()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        #if !targetEnvironment(macCatalyst)
        
//        navigationController?.navigationBar.prefersLargeTitles = true
//        navigationItem.largeTitleDisplayMode = .always;
        
        if SharedPrefs.useToolbar == true {

            if DBManager.shared.syncCoordinator != nil {
                navigationController?.setToolbarHidden(false, animated: true)
            }
            else {
                navigationController?.setToolbarHidden(true, animated: true)
            }

        }
        
        #endif
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidDisappear(true)
        
        if initialSyncCompleted == false {
            
            sync()
            
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setups
    @objc weak var refreshControl: UIRefreshControl?
    
    func setupNavigationBar() {
        
//        edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        navigationController?.navigationBar.isTranslucent = true
        
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: false)
        #else
        if let displayModeItem = splitViewController?.displayModeButtonItem {

            navigationItem.leftBarButtonItems = [displayModeItem, leftBarButtonItem]

        }

        navigationItem.rightBarButtonItem = rightBarButtonItem

        navigationItem.hidesSearchBarWhenScrolling = false
        
        // @TODO: Search Controller
        
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(beginRefreshingAll(_:)), for: .valueChanged)
        refresh.attributedTitle = lastUpdateAttributedString()
        
        collectionView.refreshControl = refresh
        
        refreshControl = refresh
        #endif
        
    }
    
    fileprivate var feedRegistration: UICollectionView.CellRegistration<FeedCell, SidebarItem>!
    fileprivate var folderRegistration: UICollectionView.CellRegistration<FolderCell, SidebarItem>!
    fileprivate var customFeedRegistration: UICollectionView.CellRegistration<CustomFeedCell, SidebarItem>!
    
    func setupCollectionView() {
        
        self.collectionView.dragInteractionEnabled = true
        
        customFeedRegistration = UICollectionView.CellRegistration<CustomFeedCell, SidebarItem>(handler: { [weak self] (cell, indexPath, item) in
            
            if case .custom(_) = item {
                
                cell.coordinator = self?.coordinator
                cell.configure(item: item, indexPath: indexPath)
                
            }
            
        })
        
        feedRegistration = UICollectionView.CellRegistration<FeedCell, SidebarItem>(handler: { [weak self] (cell, indexPath, item) in
            
            if case .feed(_) = item {
                
                cell.DS = self?.DS
                cell.configure(item: item, indexPath: indexPath)
                
            }
            
        })
        
        folderRegistration = UICollectionView.CellRegistration<FolderCell, SidebarItem>(handler: { [weak self] (cell, indexPath, item) in
            
            if case .folder(_) = item {
                
                cell.DS = self?.DS
                cell.configure(item, indexPath: indexPath)
                
            }
            
        })
        
    }
    
    func setupNotifications() {
        
        if let mc = coordinator {
            
            mc.$totalUnread
                .receive(on: DispatchQueue.main)
                .debounce(for: 0.15, scheduler: DispatchQueue.main)
                .sink { [weak self] _ in
                    
                    guard let sself = self else { return }
                    
                    if sself.requiresUpdatingUnreadsSharedData == false {
                        sself.requiresUpdatingUnreadsSharedData = true
                    }
                    
                    if Defaults[.badgeAppIcon] == true {
                        UIApplication.shared.applicationIconBadgeNumber = Int(mc.totalUnread)
                    }
                    else {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                    
                }
                .store(in: &cancellables)
            
            mc.publisher(for: \.shouldRequestReview)
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .sink { _ in
                    
                    guard mc.shouldRequestReview == true else { return }
                    
                    if let scene = mc.sidebarVC.view.window?.windowScene {
                        
                        SKStoreReviewController.requestReview(in: scene)
                        
                        let fullVersion = FeedsManager.shared.fullVersion
                        
                        Keychain.add("requestedReview-\(fullVersion)", boolean: true)
                        
                    }                    
                    
                    mc.shouldRequestReview = false
                    
                }
                .store(in: &cancellables)
            
        }
        
        DBManager.shared.publisher(for: \.lastUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                
                guard let sself = self else { return }
                
                CoalescingQueue.standard.add(sself, #selector(SidebarVC.updateLastUpdatedText))
                
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .DBManagerDidUpdate)
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sink { [weak self] note in
                
                guard let sself = self,
                      let notifications = note.userInfo?[notificationsKey] as? [Notification],
                      notifications.count > 0 else {
                    return
                }
                
                // check if any of the notifications has a change for
                // the unreads view. If we do, update the counters.
                let hasChanges: Bool = DBManager.shared.uiConnection.hasMetadataChange(forCollection: CollectionNames.articles.rawValue, in: notifications)
                
                guard hasChanges == true else { return }
                
                DispatchQueue.main.async {
                    sself.coalescingQueue.add(sself, #selector(SidebarVC.updateCounters))
                }
                
            }
            .store(in: &cancellables)
        
        SharedPrefs.publisher(for: \.hideBookmarks)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_) in
            
            self?.setupData()
            
        }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name.YTSubscriptionHasExpiredOrIsInvalid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_) in
            
            // don't run when the app is in the background or inactive
            guard UIApplication.shared.applicationState == .active else {
                return
            }
            
            // if we're already presenting a vc, don't run.
            // this is most likely the onboarding process.
            guard self?.presentedViewController == nil else {
                return
            }
            
            self?.navigationItem.rightBarButtonItem?.isEnabled = false
            
            self?.coordinator?.showSubscriptionsInterface()
            
        }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: YTSubscriptionPurchased))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_) in
            
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
            
        }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UserDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_) in
                
                guard let sself = self else {
                    return
                }
            
                FeedsManager.shared.user = DBManager.shared.user
            
                if DBManager.shared.user != nil,
                   DBManager.shared.user?.subscription?.hasExpired == false,
                   sself.initialSyncCompleted == false {
                    
                    sself.needsUpdateOfStructs = true
                    sself.sync()
                    
                }
            
        }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_) in
            
                guard let sself = self else {
                    return
                }
            
                FeedsManager.shared.user = DBManager.shared.user
            
                if DBManager.shared.user != nil,
                   DBManager.shared.user?.subscription?.hasExpired == false,
                   sself.initialSyncCompleted == false {
                    
                    sself.needsUpdateOfStructs = true
                    sself.sync()
                    
                }
            
        }
        .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: NSNotification.Name.ShowBookmarksTabPreferenceChanged, object: nil)
        
        Defaults.publisher(.showUnreadCounts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let sself = self else { return }
                sself.coalescingQueue.add(sself, #selector(sself.setupData))
            }
            .store(in: &cancellables)
        
        Defaults.publisher(.badgeAppIcon)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                
                if change.newValue == true {
                    UIApplication.shared.applicationIconBadgeNumber = Int(self?.coordinator?.totalUnread ?? 0)
                }
                else {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
                
            }
            .store(in: &cancellables)
        
        #if targetEnvironment(macCatalyst)
        
        Defaults.publisher(.refreshFeedsInterval)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let sself = self else { return }
                CoalescingQueue.standard.add(sself, #selector(sself.didChangeTimerPreference))
            }
            .store(in: &cancellables)
        
        #endif
        
    }
    
    fileprivate var initialSnapshotSetup = false
    
    @objc func setupData () {
        
        // since we only allow single selection in this collection, we get the first item. Can be nil.
        var selected: IndexPath? = collectionView.indexPathsForSelectedItems?.first
        
        var sectionSnapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>? = nil

        let s: NSDiffableDataSourceSnapshot = self.DS.snapshot()

        DispatchQueue.global().async { [weak self] in
            
            guard let sself = self else { return }
            
            if s.numberOfSections > 1 {

                let sectionIdentifier = s.sectionIdentifiers[1]

                sectionSnapshot = sself.DS.snapshot(for: sectionIdentifier)

            }

            var customSnapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem> = NSDiffableDataSourceSectionSnapshot<SidebarItem>()

            var customFeeds: [CustomFeed] = [
                CustomFeed(title: "Unread", image: "largecircle.fill.circle", color: .systemBlue, type: .unread),
                CustomFeed(title: "Today", image: "calendar", color: .systemRed, type: .today)
            ]

            if SharedPrefs.hideBookmarks == false {
                customFeeds.append(CustomFeed(title: "Bookmarks", image: "bookmark.fill", color: .systemOrange, type: .bookmarks))
            }

            customSnapshot.append(customFeeds.map { SidebarItem.custom($0) })

            runOnMainQueueWithoutDeadlocking {
                sself.DS.apply(customSnapshot, to: SidebarSection.custom.rawValue)
            }

            var foldersSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()

            if DBManager.shared.feeds.count > 0 {

                if DBManager.shared.folders.count > 0 {
                    
                    let folders: [Folder] = Array(Set(DBManager.shared.folders))

                    let uniqueFolders: [SidebarItem] = folders
                        .sorted(by: { (lhs, rhs) -> Bool in
                            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
                        })
                        .map { SidebarItem.folder($0) }

                    foldersSnapshot.append(uniqueFolders)

                    for folderItem in uniqueFolders {

                        if case .folder(let folder) = folderItem {

                            let feeds: [Feed] = Array(Set(folder.feeds))

                            if feeds.count > 0 {

                                let uniqueFeeds: [SidebarItem] = feeds
                                    .sorted(by: { (lhs, rhs) -> Bool in
                                        
                                        return lhs.displayTitle.localizedCompare(rhs.displayTitle) == .orderedAscending
                                        
                                    })
                                    .map { SidebarItem.feed($0) }

                                foldersSnapshot.append(uniqueFeeds, to: folderItem)

                            }

                            // if the folder was originally in the expanded state, expand it from here too so the visual state is maintained.
                            if let sc = sectionSnapshot,
                               sc.items.count > 0,
                               sc.contains(folderItem) == true,
                               sc.isExpanded(folderItem) {

                                foldersSnapshot.expand([folderItem])

                            }

                        }

                    }

                }

                do {
                    runOnMainQueueWithoutDeadlocking {
                        try? sself.DS.apply(foldersSnapshot, to: SidebarSection.folders.rawValue)
                    }
                }
                catch {
                    print(error)
                }
                
                let feedsWithoutFolders: [Feed] = DBManager.shared.feeds.filter { $0.folderID == nil || $0.folderID == 0 }
                
                var feedsSnapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem> = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                
                if feedsWithoutFolders.count > 0 {
                    
                    let alphaSorted = Array(Set(feedsWithoutFolders)).sorted { (lhs, rhs) -> Bool in
                        return lhs.displayTitle.localizedCompare(rhs.displayTitle) == .orderedAscending
                    }
                        
                    feedsSnapshot.append(alphaSorted.map { SidebarItem.feed($0) })
                    
                }
                
                runOnMainQueueWithoutDeadlocking {
                    sself.DS.apply(feedsSnapshot, to: SidebarSection.feeds.rawValue)
                }
                
            }
            
            if sself.needsUpdateOfStructs == true && sself.initialSyncCompleted == true {
                sself.needsUpdateOfStructs = false
            }
            
            #if targetEnvironment(macCatalyst)
            
            if sself.initialSnapshotSetup == false {
                
                if let item = customSnapshot.items.first {
                    // select Unread on launch
                    selected = sself.DS.indexPath(for: item)
                }
                
                sself.initialSnapshotSetup = true
            }
            
            #endif
            
            if let s = selected {
                
                runOnMainQueueWithoutDeadlocking {
                    
                    sself.collectionView.selectItem(at: s, animated: false, scrollPosition: .init())
                    
                }
                
            }
            
        }
        
    }
    
    lazy var leftBarButtonItem: UIBarButtonItem = {
        
        let coordinator = self.coordinator!
       
        var image = UIImage(systemName: "gear")
        var b = UIBarButtonItem(image: image, style: .plain, target: coordinator, action: #selector(coordinator.showSettingsVC))
        
        return b
        
    }()
    
    lazy var rightBarButtonItem: UIBarButtonItem = {
        
        let newFolderImage = UIImage(systemName: "folder.badge.plus"),
            newFeedImage = UIImage(systemName: "plus")
        
        let coordinator = self.coordinator!
        
        let addItem = UIAction(title: "New Feed", image: newFeedImage, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { (a) in
            
            coordinator.showNewFeedVC()
            
        }
        
        let addFolderItem = UIAction(title: "New Folder", image: newFolderImage, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { (a) in
            
            coordinator.showNewFolderVC()
            
        }
        
        let menu = UIMenu(title: "New", image: newFeedImage, identifier: nil, options: [], children: [addItem, addFolderItem])
        
        let item = UIBarButtonItem(systemItem: .add, primaryAction: nil, menu: menu)
        
        return item
        
    }()
    
    weak var progressLabel: UILabel?
    weak var progressView: UIProgressView?
    
    lazy var progressStackView: UIStackView = {
       
        let frame = CGRect(x: 0, y: 0, width: view.bounds.size.width - 24, height: 32)
        
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 0)
        
        let labelWidthConstraint = label.widthAnchor.constraint(equalToConstant: max(frame.size.width, 280))
        labelWidthConstraint.priority = UILayoutPriority(rawValue: 999)
        labelWidthConstraint.isActive = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = SharedPrefs.tintColor
        progressView.trackTintColor = .separator
        progressView.frame = CGRect(x: 0, y: 0, width: max(frame.size.width, 280), height: 6)
        progressView.layer.cornerRadius = 2
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        SharedPrefs
            .publisher(for: \.tintColor)
            .sink(receiveValue: { (color) in
                progressView.progressTintColor = color
                progressView.tintColor = color
            })
            .store(in: &cancellables)
        
        let progressWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: max(frame.size.width, 280))
        progressWidthConstraint.priority = UILayoutPriority(rawValue: 999)
        progressWidthConstraint.isActive = true
        
        var psv = UIStackView(arrangedSubviews: [label, progressView])
        psv.frame = frame
        psv.axis = .vertical
        psv.distribution = .equalSpacing
        psv.spacing = 4
        psv.alignment = .center
        
        self.progressLabel = label
        self.progressView = progressView
        
        return psv
        
    }()
    
    public override var toolbarItems: [UIBarButtonItem]? {
        
        get {
            return [UIBarButtonItem(customView: progressStackView)]
        }
        
        set {
            super.toolbarItems = newValue
        }
        
    }
    
    func lastUpdateAttributedString() -> NSAttributedString {
        
        let common: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        guard let date = DBManager.shared.lastUpdated else {
            
            let string = "Not Synced"
            return NSAttributedString(string: string, attributes: common)
            
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        
        let ds = formatter.string(from: date)
        let formatted = "Last Sync: \(ds)"
        
        return NSAttributedString(string: formatted, attributes: common)
        
    }
    
    func updateLastUpdatedText() {
        
        refreshControl?.attributedTitle = lastUpdateAttributedString()
        
    }
    
    // MARK: - Actions
    public override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func show(activityController: UIActivityViewController, indexPath: IndexPath?) {
        
        if let indexPath = indexPath,
           splitViewController?.traitCollection.horizontalSizeClass == .regular,
           let pvc = activityController.popoverPresentationController,
           let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            
            pvc.sourceView = collectionView
            pvc.sourceRect = attributes.frame
            
        }
        
        present(activityController, animated: true, completion: nil)
        
    }
    
    @objc func shareFeedURL(_ feed: Feed, indexPath: IndexPath, completion: ((_ completed: Bool) -> Void)?) {
        
        guard let url = feed.url else {
            return
        }
        
        let avc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        present(avc, animated: true) {
            completion?(true)
        }
        
    }
    
    @objc func shareWebsiteURL(_ feed: Feed, indexPath: IndexPath) {
        
        guard let url = feed.extra?.url else {
            return
        }
        
        let avc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        show(activityController: avc, indexPath: indexPath)
        
    }
    
    @objc func delete(feed: Feed, indexPath: IndexPath, completion: ((_ completed: Bool) -> Void)?) {
        
        AlertManager.showDestructiveAlert(title: "Delete Feed", message: "Are you sure you want to delete this feed?", confirm: "Delete", confirmHandler: { [weak self] (_) in
            
            guard let sself = self else {
                completion?(false)
                return
            }
            
            if feed.folderID != nil,
               let folder = DBManager.shared.folder(for: feed.folderID!) {
                
                FeedsManager.shared.update(folder: folder.folderID, title: nil, add: nil, delete: [feed.feedID]) { [weak self] result in
                    
                    if case .success(let res) = result,
                       res == true {
                        folder.feedIDs = folder.feedIDs.filter { $0 != feed.feedID }
                    }
                    
                    self?._deleteFeed(feed: feed, completion: completion)
                    
                }
                
            }
            else {
                sself._deleteFeed(feed: feed, completion: completion)
            }
            
            
        }, cancel: "Cancel", cancelHandler: nil, from: self)
        
    }
    
    func _deleteFeed(feed: Feed, completion: ((_ completed: Bool) -> Void)?) {
        
        FeedsManager.shared.delete(feed: feed.feedID) { (result) in
            
            switch result {
            case .failure(let error):
                completion?(false)
                AlertManager.showGenericAlert(withTitle: "Error Deleting Feed", message: error.localizedDescription)
                
            case .success(_):
                completion?(true)
                
                DBManager.shared.delete(feed: feed)
            
            }
            
        }
        
    }
    
    @objc func showInfo(feed: Feed, indexPath: IndexPath) {
        
        coordinator?.showFeedInfo(feed: feed, from: self, completion: nil)
        
    }
    
    @objc func move(feed: Feed, indexPath: IndexPath, completion: ((_ completed: Bool) -> Void)?) {
        
        coordinator?.showFeedInfo(feed: feed, from: self, completion: { [weak self] in
            
            self?.coordinator?.showFolderInfo()
            
        })
        
    }
    
    @objc func rename(folder: Folder, indexPath: IndexPath) {
        
        coordinator?.showRenameFolderVC(folder)
        
    }
    
    @objc func delete(folder: Folder, indexPath: IndexPath, completion:((_ completed: Bool) -> Void)?) {
        
        AlertManager.showDestructiveAlert(title: "Delete Folder", message: "Are you sure you want to delete this folder?", confirm: "Delete", confirmHandler: { [weak self] (_) in
            
            guard let sself = self else {
                return
            }
            
            FeedsManager.shared.delete(folder: folder.folderID) { (result) in
                
                switch result {
                case .failure(let error):
                    AlertManager.showGenericAlert(withTitle: "Error Deleting Feed", message: error.localizedDescription)
                    
                    completion?(false)
                    
                case .success(_):
                    DBManager.shared.delete(folder: folder)
                    
                    DispatchQueue.main.async {
                        sself.setupData()
                    }
                    
                    completion?(true)
                
                }
                
            }
            
        }, cancel: "Cancel", cancelHandler: nil, from: self)
        
    }
    
    // MARK: - Sync
    fileprivate var fetchingCounters: Bool = false
    
    @objc func beginRefreshingAll(_ sender: Any?) {
        
        guard DBManager.shared.syncCoordinator == nil else {
            
            if let r = sender as? UIRefreshControl,
               r.isRefreshing == true {
                
                r.endRefreshing()
                
            }
            
            return
            
        }
        
        fetchingCounters = false
        
        sync()
        
    }
    
    @objc public var needsUpdateOfStructs: Bool = false {
        
        didSet {
            if needsUpdateOfStructs == true {
                setupData()
            }
        }
        
    }
    
    fileprivate var refreshFeedsCount: Int = 0
    
    @objc public var backgroundFetchHandler: ((_ result: UIBackgroundFetchResult) -> Void)?
    
    fileprivate var isRefreshing: Bool = false
    
    // called when a force resync of feeds or all data is done.
    @objc public func resetSync() {
        
        initialSyncCompleted = false
        needsUpdateOfStructs = true
        
        beginRefreshingAll(refreshControl)
        
    }
    
    @objc func sync() {
        
        guard FeedsManager.shared.user != nil else {
            return
        }
        
        guard FeedsManager.shared.user?.subscription != nil,
              FeedsManager.shared.user!.subscription?.hasExpired == false else {
            
            // fetch the subscription just in case.
            coordinator?.getSubscription(completion: { [weak self] error in
                
                guard let sself = self else { return }
                
                if let error = error {
                    AlertManager.showGenericAlert(withTitle: "No Subscription", message: error.localizedDescription)
                    return
                }
                
                sself.coalescingQueue.add(sself, #selector(SidebarVC.sync))
                
            })
            
            return
        }
        
        if (needsUpdateOfStructs == true)
            && refreshFeedsCount < 3 {
            
            refreshFeedsCount += 1
            
            FeedsManager.shared.getFeeds { [weak self] (result) in
                
                guard let sself = self else {
                    return
                }
                
                switch result {
                case .success(let result):
                    
                    DispatchQueue.main.async {
                        
                        let feeds = result.feeds
                        let folders = result.folders
                        
                        DBManager.shared.feeds = feeds
                        DBManager.shared.folders = folders
                        
                        if sself.needsUpdateOfStructs == true {
                            sself.needsUpdateOfStructs = false
                        }
                        
                        sself.setupData()
                        
                        sself.backgroundFetchHandler?(.newData)
                        
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        
                        sself.refreshFeedsCount = 0
                        sself.sync()
                        
                    }
                    
                case .failure(_):
                    sself.backgroundFetchHandler?(.failed)
                    if sself.refreshFeedsCount > 0 {
                        sself.sync()
                    }
                }
                
            }
            
            return
            
        }
        
        refreshFeedsCount = 0
        
        if initialSyncCompleted == false {
            
            updateCounters()
            initialSyncCompleted = true
            
            NotificationCenter.default.publisher(for: .feedsUpdated)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (_) in
                
                    guard let sself = self else { return }
                    
                    sself.coalescingQueue.add(sself, #selector(SidebarVC.setupData))
                
                }.store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: .foldersUpdated)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (_) in
                
                    guard let sself = self else { return }
                    
                    sself.coalescingQueue.add(sself, #selector(SidebarVC.setupData))
                
                }.store(in: &cancellables)
            
        }
        
        if isRefreshing == true {
            return
        }
        
        if DBManager.shared.syncCoordinator != nil {
            return
        }
        
        isRefreshing = true
        
        if self.backgroundFetchHandler != nil {
            // we only need to update feeds.
            self.backgroundFetchHandler = nil
        }
        
        if refreshControl?.isRefreshing == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.refreshControl?.beginRefreshing()
            }
        }
        
        isRefreshing = true
        
        let syncCoordinator = SyncCoordinator()
        syncCoordinator.syncProgressCallback = { [weak self] (progress) in
            
            guard let sself = self else {
                return
            }
            
            #if DEBUG
            print("Sync Progress: \(progress)")
            #endif
            
            let animated = UIApplication.shared.applicationState == UIApplication.State.active
            
            sself.progressView?.setProgress(Float(progress), animated: animated)
            
            if progress == 1 {
                
                if sself.backgroundFetchHandler != nil {
                    sself.backgroundFetchHandler?(.newData)
                }
                
                if sself.refreshControl?.isRefreshing == true {
                    DispatchQueue.main.async {
                        sself.additionalSafeAreaInsets = .zero
                        sself.refreshControl?.endRefreshing()
                        DBManager.shared.lastUpdated = Date()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    
                    sself.navigationController?.setToolbarHidden(true, animated: animated)
                    
                }
                
                if DBManager.shared.user != nil {
                    DBManager.shared.bookmarksCoordinator = BookmarksCoordinator(user: DBManager.shared.user!)
                    DBManager.shared.bookmarksCoordinator!.start()
                }
                
                if let mc = sself.coordinator,
                   let f = mc.feedVC,
                   f is UnreadVC || f is TodayVC {
                    
                    f._didSetSortingOption()
                    
                }
                
                DBManager.shared.syncCoordinator = nil
            
            }
            
            if progress == 0 {
                sself.navigationController?.setToolbarHidden(false, animated: animated)
                sself.progressLabel?.text = "Syncing..."
                sself.progressLabel?.sizeToFit()
                sself.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: sself.navigationController?.toolbar?.bounds.size.height ?? 44, right: 0)
            }
            else if progress >= 0.99 {
             
                sself.progressLabel?.text = "Syncing Complete"
                sself.progressLabel?.sizeToFit()
                
                if sself.isRefreshing == true {
                    
                    sself.isRefreshing = false
                    
                }
                
            }
            else {
                
                if sself.navigationController?.isToolbarHidden == false {
                    
                    sself.progressLabel?.text = String(format: "Synced %.f%%", progress * 100)
                    sself.progressLabel?.sizeToFit()
                    
                }
                
            }
            
        }
        
        DBManager.shared.syncCoordinator = syncCoordinator
        
        syncCoordinator.setupSync()
        
    }
    
//    fileprivate var unreadWidgetsTimer: Timer?
    
    @objc func updateSharedUnreadsData() {
        
//        guard Thread.isMainThread == true else {
//
//            performSelector(onMainThread: #selector(updateSharedUnreadsData), with: nil, waitUntilDone: false)
//
//            return
//        }
//
//        var interval: Double = 0
//
//        if unreadWidgetsTimer != nil {
//
//            interval = 2
//
//            unreadWidgetsTimer?.invalidate()
//            unreadWidgetsTimer = nil
//        }
//
//        unreadWidgetsTimer = Timer(timeInterval: interval, repeats: false, block: { (_) in
            
            DBManager.shared.uiConnection.asyncRead { [weak self] (t) in
                
                guard let sself = self else { return }
                
                guard let txn = t.ext(DBManagerViews.unreadsView.rawValue) as? YapDatabaseFilteredViewTransaction else {
                    return
                }
                
                var items: [Article] = []
                
                txn.enumerateKeysAndObjects(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, 10)) { (_, _) -> Bool in
                    return true
                } using: { (c, key, object, index, stop) in
                    
                    guard let item = object as? Article else {
                        return
                    }
                    
                    items.append(item)
                    
                }

                DBManager.shared.writeQueue.async {
                    
                    let usableItems: [Article] = items
                    
//                    let coverItems = items.filter { $0.coverImage != nil }
//
//                    if coverItems.count >= 4 {
//                        usableItems = coverItems
//                    }
//                    else {
//
//                        /*
//                         * A: Say we have 1 item with a cover. So we take the other 3 non-cover items
//                         *    and concat it here.
//                         *
//                         * B: Say we have 3 items with covers. We take the first non-cover item
//                         *    and use it here.
//                         */
//
//                        let coverItemsCount = coverItems.count
//                        var additionalRequired = max(0, 4 - coverItemsCount)
//
//                        let nonCoverItems = items.filter { $0.coverImage == nil }
//
//                        if nonCoverItems.count > 0 {
//
//                            additionalRequired = min(additionalRequired, nonCoverItems.count)
//
//                            usableItems = coverItems
//
//                            nonCoverItems.suffix(additionalRequired).forEach { usableItems.append($0) }
//
//                        }
//
//                    }
                    
                    // Actually stores WidgetArticle before writing to disk.
                    var list: [Article] = []
                    
                    if usableItems.count > 0 {
                        
                        let upperBound = max(0, min(4, usableItems.count))
                        
                        list = Array(usableItems[0..<upperBound])
                        
                        let widgetList: [WidgetArticle] = list.map { WidgetArticle.init(copyFrom: $0) }
                        
                        // get the feeds for these articles
                        for article in widgetList {
                            
                            if let feed = DBManager.shared.feed(for: article.feedID) {
                                article.blog = feed.displayTitle
                                article.favicon = feed.faviconProxyURI(size: 32)
                            }
                            
                            if article.title == nil || (article.title != nil && article.title!.isEmpty) {
                                // micro.blog post.
                                
                                if article.summary == nil || article.summary?.isEmpty == true {
                                    
                                    if let content = t.object(forKey: article.identifier, inCollection: CollectionNames.articlesContent.rawValue) as? [Content] {
                                        
                                        article.content = content
                                        article.summary = article.textFromContent
                                        
                                        article.content = []
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        list = widgetList
                        
                    }
                    
                    let encoder = JSONEncoder()
                    if let data = try? encoder.encode(list) {
                        
                        sself.coordinator?.writeTo(sharedFile: "articles.json", data: data)
                        WidgetManager.reloadTimeline(name: "UnreadsWidget")
                        
                    }
                    
                    sself.requiresUpdatingUnreadsSharedData = false
                    
                }
                
            }
            
//        })
//
//        RunLoop.main.add(unreadWidgetsTimer!, forMode: .common)
        
    }
    
    // Mark: - Mac
    #if targetEnvironment(macCatalyst)
    
    var refreshTimer: Timer?
    
    @objc func didChangeTimerPreference () {
        
        if refreshTimer != nil {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        
        scheduleTimerIfValid()
        
    }
    
    @objc func scheduleTimerIfValid () {
        
        guard refreshTimer == nil else {
            // already scheduled
            return
        }
        
        guard var interval = RefreshIntervalKeys(rawValue: Defaults[.refreshFeedsInterval])?.interval,
              interval > 0 else {
            return
        }
        
        #if DEBUG
        // half hour = 2.5min, full hour = 5min
        interval *= 5
        #else
        interval *= 60
        #endif
        
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] (t) in
            
            guard let sself = self else { return }
            
            print("Timer called at \(t.fireDate), refreshing counters and feeds.")
            
            sself.beginRefreshingAll(nil)
            
        }
        
        print("Scheduling timer with time interval \(interval)")
        
        RunLoop.main.add(timer, forMode: .default)
        
        refreshTimer = timer
        
    }
    
    #endif
    
}

// MARK: - UICollectionViewDelegate
extension SidebarVC {
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: false)
            return
        }
        
        switch item {
        case .custom(let c):
            coordinator?.showCustomVC(c)
        case .feed(let f):
            coordinator?.showFeedVC(f)
        case .folder(let f):
            coordinator?.showFolderVC(f)
        }
        
        // @TODO: Restoration activity
        
    }
    
    public override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let object = DS.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        switch object {
        case .feed(let f):
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) -> UIMenu? in
                
                guard let sself = self else {
                    return nil
                }
                
                var share: UIMenuElement!
                
                if f.canShowExtraLevel {
                    
                    let shareFeed = UIAction(title: "Share Feed URL", image: UIImage(systemName: "sqaure.and.arrow.up"), identifier: nil) { (_) in
                        
                        sself.shareFeedURL(f, indexPath: indexPath, completion: nil)
                        
                    }
                    
                    let shareWebsite = UIAction(title: "Share Website URL", image: UIImage(systemName: "sqaure.and.arrow.up"), identifier: nil) { (_) in
                        
                        sself.shareWebsiteURL(f, indexPath: indexPath)
                        
                    }
                    
                    share = UIMenu(title: "Share", children: [shareFeed, shareWebsite])
                    
                }
                else {
                    
                    share = UIAction(title: "Share Feed URL", image: UIImage(systemName: "sqaure.and.arrow.up"), identifier: nil) { (_) in
                        
                        sself.shareFeedURL(f, indexPath: indexPath, completion: nil)
                        
                    }
                    
                }
                
                let rename = UIAction(title: "Rename", image: UIImage(systemName: "pencil"), identifier: nil) { (_) in
                    
                    sself.rename(feed: f, indexPath: indexPath)
                    
                }
                
                let move = UIAction(title: "Move", image: UIImage(systemName: "text.insert"), identifier: nil) { (_) in
                    
                    sself.move(feed: f, indexPath: indexPath, completion: nil)
                    
                }
                
                let feedInfo = UIAction(title: "Feed Info", image: UIImage(systemName: "info.circle.fill"), identifier: nil) { (_) in
                    
                    sself.showInfo(feed: f, indexPath: indexPath)
                    
                }
                
                let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil) { (_) in
                    
                    sself.delete(feed: f, indexPath: indexPath, completion: nil)
                    
                }
                
                delete.attributes = .destructive
                
                return UIMenu(title: "Feed Menu", children: [share, rename, feedInfo, move, delete])
                
            }
            
        case .folder(let f):
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) -> UIMenu? in
                
                guard let sself = self else {
                    return nil
                }
                
                let rename = UIAction(title: "Rename", image: UIImage(systemName: "pencil"), identifier: nil) { (_) in
                    
                    sself.rename(folder: f, indexPath: indexPath)
                    
                }
                
                let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil) { (_) in
                    
                    sself.delete(folder: f, indexPath: indexPath, completion: nil)
                    
                }
                
                delete.attributes = .destructive
                
                return UIMenu(title: "Folder Menu", children: [rename, delete])
                
            }
            
        default:
            return nil
        }
        
    }
    
}

extension SidebarVC {
    
    @objc func updateCounters() {
        
        print("Updating counters")
        
        DBManager.shared.writeQueue.async { [weak self] in 
            
            DBManager.shared.countsConnection.asyncRead { (t) in
                
                guard let sself = self,
                      let txn = t.ext(DBManagerViews.unreadsView.rawValue) as? YapDatabaseFilteredViewTransaction,
                      let btxn = t.ext(DBManagerViews.bookmarksView.rawValue) as? YapDatabaseFilteredViewTransaction else {
                    return
                }
                
                let group = GroupNames.articles.rawValue
                
                self?.coordinator?.totalBookmarks = btxn.numberOfItems(inGroup: group)
                
                let total = Int(txn.numberOfItems(inGroup: group))
                
                guard total > 0 else {
                    
                    DBManager.shared.feeds.forEach { $0.unread = 0 }
                    
                    sself.coordinator?.totalUnread = 0
                    sself.coordinator?.totalToday = 0
                    
                    return
                }
                
                let folders = DBManager.shared.folders
                
                for folder in folders {
                    folder.updatingCounters = true
                }
                
                // feedID : Unread Count
                var feedsMapping: [UInt: UInt] = [:]
                
                // Ensure 0 reads are also updated.
                DBManager.shared.feeds.forEach { feedsMapping[$0.feedID] = 0 }
                
                var totalToday: UInt = 0
                
                let calendar = NSCalendar.current
                
                txn.enumerateKeysAndMetadata(inGroup: group, with: [], range: NSMakeRange(0, total)) { (c, k) -> Bool in
                    return true
                } using: { (c, k, metadata, index, stop) in
                    
                    guard let metadata = metadata as? ArticleMeta,
                          metadata.read == false else {
                        return
                    }
                    
                    let feedID = metadata.feedID
                    
                    if feedsMapping[feedID] == nil {
                        feedsMapping[feedID] = 0
                    }
                    
                    if calendar.isDateInToday(Date(timeIntervalSince1970: metadata.timestamp)) {
                        totalToday += 1
                    }
                    
                    feedsMapping[feedID]! += 1
                    
                }
                
                let unread = feedsMapping.values.reduce(0) { (result, c) -> UInt in
                    return result + c
                }
                
                sself.coordinator?.totalUnread = unread
                sself.coordinator?.totalToday = totalToday
                
                print(feedsMapping)
                
                for feedID in feedsMapping.keys {
                    
                    guard let feed = DBManager.shared.feedForID(feedID) else {
                        continue
                    }
                    
                    feed.unread = feedsMapping[feedID] ?? 0
                    
                }
                
                for folder in folders {
                    folder.updatingCounters = false
                }
                
            }
            
        }
        
    }
    
}

// MARK: - Rename Feed
extension SidebarVC: UITextFieldDelegate {
    
    func clearAlertProperties () {
        alertDoneAction = nil
        alertTextField = nil
        alertFeed = nil
    }
    
    @objc func rename(feed: Feed, indexPath: IndexPath) {
        
        alertFeed = feed
        
        let avc = UIAlertController(title: "Rename Feed", message: nil, preferredStyle: .alert)
        
        let done = UIAlertAction(title: "Done", style: .default) { [weak self] (_) in
            
            guard let sself = self,
                  let stf = sself.alertTextField,
                  let f = sself.alertFeed else {
                
                self?.clearAlertProperties()
                
                return
            }
            
            let name = (stf.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            sself.coordinator?.rename(feed: f, title: name, completion: { status in
                
                if status == true {
                    
                    if let cell = sself.collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell,
                       var config = cell.contentConfiguration as? UIListContentConfiguration {
                        
                        config.text = f.displayTitle
                        
                        cell.contentConfiguration = config
                        
                    }
                    
                }
                                
                sself.clearAlertProperties()
                
            })
            
        }
        
        avc.addAction(done)
        
        alertDoneAction = done
        
        avc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (_) in
            
            guard let sself = self else {
                return
            }
            
            sself.clearAlertProperties()
            
        }))
        
        avc.addTextField { [weak self] (t) in
            
            self?.alertTextField = t
            
            t.placeholder = "Feed Name"
            t.text = feed.localName ?? ""
            
            t.delegate = self
            
        }
        
        if feed.localName != nil {
            alertDoneAction?.isEnabled = true
        }
        else {
            alertDoneAction?.isEnabled = ((feed.localName ?? feed.title)?.trimmingCharacters(in: .whitespaces).count ?? 0) >= 3
        }
        
        present(avc, animated: true) { [weak self] in
            
            self?.alertTextField?.becomeFirstResponder()
            
        }
        
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).trimmingCharacters(in: .whitespacesAndNewlines)
        
        alertDoneAction?.isEnabled = newText.count >= 3
        
        return true
        
    }
    
}
