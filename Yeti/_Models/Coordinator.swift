//
//  Coordinator.swift
//  Elytra
//
//  Created by Nikhil Nigade on 25/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Defaults
import UserNotifications
import Networking
import DZNetworking
import Dynamic
import Models
import DBManager
import DZKit
import DeviceCheck
import Combine
import OrderedCollections
import BackgroundTasks
import SwiftYapDatabase
import YapDatabase
import FeedsLib

public var deviceName: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    
    let identifier: String = withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            ptr in String.init(validatingUTF8: ptr)!
        }
    }
    
    return identifier
}

@objc public enum ShowOPMLType: Int {
    case Import
    case Export
}

@objcMembers public class Coordinator: NSObject {
    
    @Published var totalUnread: UInt = 0
    @Published var totalToday: UInt = 0
    @Published var totalBookmarks: UInt = 0
    
    weak public var splitVC: SplitVC!
    weak public var sidebarVC: SidebarVC!
    weak public var feedVC: FeedVC?
    weak public var articleVC: ArticleVC?
    weak public var emptyVC: EmptyVC?
    
    public var importingInProgress: Bool = false
    
    weak public var activityDialog: UIAlertController?
    
    var cancellables: [AnyCancellable] = []
    
    public func start(_ splitViewController: SplitVC) {
        
        setupDeviceID()
        
        self.splitVC = splitViewController
        splitViewController.coordinator = self
        
        let sidebar = SidebarVC()
        sidebar.coordinator = self
        
        let nav = UINavigationController(rootViewController: sidebar)

        splitVC.setViewController(nav, for: .compact) // only used on iPads :/
        splitVC.setViewController(nav, for: .primary)
        
        self.sidebarVC = sidebar
        
        var showUnread = SharedPrefs.openUnread
        var showEmpty = false
        
        if let traits: UITraitCollection = UIApplication.shared.windows.first?.traitCollection {
        
            if traits.userInterfaceIdiom != .phone,
               traits.horizontalSizeClass == .regular {
                
                if traits.userInterfaceIdiom == .mac {
                    showUnread = showUnread || true
                }
                
                showEmpty = true
                
            }
            
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let sself = self else { return }
            
            if showUnread {
                sself.showUnreadVC()
            }
            
            if showEmpty {
                sself.showEmptyVC()
            }
            
            sself.checkConstraintsForRequestingReview()
            sself.checkForPushNotifications()
            
        }
        
        setupNotifications()
        
    }
    
    func setupDeviceID() {
        
        let deviceID: String? = try? Keychain.string(for: "deviceID")
        
        if deviceID == nil {
            
            FeedsManager.shared.deviceID = deviceID
            
            return
            
        }
        
        let device = DCDevice.current
        
        if device.isSupported {
            
            device.generateToken { [weak self] token, error in
                
                guard error == nil else {
                    self?._setupDeviceIDUsingUUID()
                    return
                }
                
                guard let token = token else {
                    self?._setupDeviceIDUsingUUID()
                    return
                }
                
                let encoded: Data = token.base64EncodedData()
                
                guard let tokenString = String(data: encoded, encoding: .utf8) else {
                    
                    self?._setupDeviceIDUsingUUID()
                    return
                    
                }
                
                let tokenMD5: String = (tokenString as NSString).md5()
                
                FeedsManager.shared.deviceID = tokenMD5
                
                Keychain.add("deviceID", string: tokenMD5)
                Keychain.add("rawDeviceID", data: token)
                
            }
            
        }
        else {
            
            _setupDeviceIDUsingUUID()
            
        }
        
    }
    
    public func _setupDeviceIDUsingUUID() {
        
        let deviceID: String = UUID().uuidString
        
        FeedsManager.shared.deviceID = deviceID
        
        Keychain.add("deviceID", string: deviceID)
        
    }
    
    func setupNotifications() {
        
        NotificationCenter.default.publisher(for: .DBManagerDidUpdate)
            .debounce(for: 0.2, scheduler: DBManager.shared.writeQueue)
            .filter { $0.userInfo?[notificationsKey] != nil && ($0.userInfo?[notificationsKey]! as? [Notification])?.count ?? 0 > 0  }
            .sink { [weak self] notification in
                
                // we only check if a folder is selected for the Folders Widget
                guard WidgetManager.usingFoldersWidget == true,
                      let _ = WidgetManager.selectedFolder else {
                    return
                }
                
                guard let fIDString = WidgetManager.selectedFolder?.identifier as NSString? else {
                    return
                }
                
                let folderID = UInt(fIDString.integerValue)
                
                guard let sself = self,
                      let notifications = notification.userInfo?[notificationsKey] as? [Notification],
                      let ext = DBManager.shared.uiConnection.ext(dbFilteredViewName) as? YapDatabaseFilteredViewConnection,
                      ext.hasChanges(for: notifications) else {
                        return
                      }
                
                guard DBManager.shared.countsConnection.hasMetadataChange(forCollection: CollectionNames.articles.rawValue, in: notifications) == true else {
                    return
                }
                
                guard let set = notifications[0].userInfo!["metadataChanges"] as? YapSet else {
                    return
                }
                
                var folderChanged: Bool = false
                
                DBManager.shared.countsConnection.read { t in
                    
                    set.enumerateObjects { i, stop in
                        
                        if let ck = i as? YapCollectionKey,
                           ck.collection == CollectionNames.articles.rawValue {
                            
                            // check if this key is in our folder
                            guard let metadata = t.metadata(forKey: ck.key, inCollection: ck.collection) as? ArticleMeta,
                                  let feed = DBManager.shared.feed(for: metadata.feedID),
                                  feed.folderID == folderID else {
                                
                                return
                                
                            }
                            
                            folderChanged = true
                            stop.pointee = true
                            
                        }
                        
                    }
                    
                }
                
                if (folderChanged) {
                    CoalescingQueue.standard.add(sself, #selector(Coordinator.updateSharedFoldersArticles))
                }
                
//                print(notifications)
                
            }
            .store(in: &cancellables)
        
    }
    
    // MARK: - Feeds
    public func showUnreadVC() {
        let f = CustomFeed(title: "Unread", image: "largecircle.fill.circle", color: .systemBlue, type: .unread)
        
        showCustomVC(f)
    }
    
    public func showCustomVC(_ feed: CustomFeed) {
        
        if feed.feedType == .unread && (self.feedVC == nil || (self.feedVC != nil && self.feedVC!.type != .unread)) {
            
            self.feedVC = nil
            
            let unread = UnreadVC(style: .plain)
            unread.type = .unread
            showSupplementaryController(unread)
            
        }
        else if feed.feedType == .today {
            
            let today = TodayVC(style: .plain)
            showSupplementaryController(today)
            
        }
        else if feed.feedType == .bookmarks {
            
            let bookmarks = BookmarksVC(style: .plain)
            showSupplementaryController(bookmarks)
            
        }
        
    }
    
    public func showFeedVC(_ feed: Feed) {
        
        let feedVC = FeedVC(style: .plain)
        feedVC.feed = feed
        
        showSupplementaryController(feedVC)
        
    }
    
    public func showFolderVC (_ folder: Folder) {
        
        let folderVC = FolderVC(style: .plain)
        folderVC.folder = folder
        
        showSupplementaryController(folderVC)
        
    }
    
    public func showAuthorVC(_ feed: Feed, author: String) {
        
        let feedVC = AuthorVC(style: .plain)
        feedVC.feed = feed
        feedVC.author = author
        
        showSupplementaryController(feedVC)
        
    }
    
    // MARK: - Articles
    public func showArticleVC(_ articleVC: ArticleVC) {
        
        articleVC.coordinator = self
        
        self.articleVC = articleVC
        
        if let fvc = self.feedVC {
            articleVC.providerDelegate = fvc
        }
        
        showDetailController(articleVC)
        
        if let splitVC = splitVC,
           splitVC.traitCollection.userInterfaceIdiom == .pad,
           splitVC.view.bounds.width < splitVC.view.bounds.height {
            
            runOnMainQueueWithoutDeadlocking {
                
                UIView.animate(withDuration: 0.125) {
                    splitVC.preferredDisplayMode = .secondaryOnly
                }
                
            }
            
        }
        
    }
    
    public func showArticle(_ article: Article) {
        
        let vc = ArticleVC(item: article)
        
        showArticleVC(vc)
        
    }
    
    // MARK: - Misc
    
    public func showEmptyVC( ) {
        
        let vc = EmptyVC(nibName: "EmptyVC", bundle: Bundle.main)
        
        splitVC.setViewController(vc, for: .secondary)
        
    }
    
    public func showLaunchVC() {
        
        guard let splitVC = self.splitVC, splitVC.presentedViewController == nil else {
            return
        }
        
        let vc = LaunchVC(nibName: "LaunchVC", bundle: Bundle.main)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        
        if splitVC.traitCollection.userInterfaceIdiom != .phone,
           splitVC.traitCollection.horizontalSizeClass == .regular {
            
            nav.modalPresentationStyle = .formSheet
            
        }
        else {
            nav.modalPresentationStyle = .fullScreen
        }
        
        nav.isModalInPresentation = true
        
        splitVC.present(nav, animated: true, completion: nil)
        
    }
    
    public func showSubscriptionsInterface() {
        
        #if targetEnvironment(macCatalyst)
        openScene(name: "subscriptionInterface")
        #else
        let vc = StoreVC(style: .plain)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        splitVC.present(nav, animated: true, completion: nil)
        #endif
        
    }
    
    public func showNewFeedVC() {
        
        #if targetEnvironment(macCatalyst)
        openScene(name: "newFeedScene")
        #else
        
        let vc = NewFeedVC(collectionViewLayout: NewFeedVC.gridLayout)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        splitVC?.present(nav, animated: true, completion: nil)
        
        #endif
        
    }
    
    var newFolderController: NewFolderController?
    
    public func showNewFolderVC() {
        
        self.newFolderController = NewFolderController(folder: nil, coordinator: self) { [weak self] folder, completed, error in
            
            if let error = error {
                AlertManager.showGenericAlert(withTitle: "Error Adding Folder", message: error.localizedDescription)
                return
            }
            
            self?.newFolderController = nil
            
        }
        
        self.newFolderController?.start()
        
    }
    
    public func showRenameFolderVC(_ folder: Folder) {
        
        self.newFolderController = NewFolderController(folder: folder, coordinator: self) { [weak self] folder, completed, error in
            
            if let error = error {
                AlertManager.showGenericAlert(withTitle: "Error Updating Folder", message: error.localizedDescription)
                return
            }
            
            self?.newFolderController = nil
            
        }
        
        self.newFolderController?.start()
        
    }
    
    // Not used for macOS. macOS uses the native Preferences style window instead.
    public func showSettingsVC () {
        
        let vc = SettingsVC(nibName: "SettingsVC", bundle: nil)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        
        splitVC.present(nav, animated: true, completion: nil)
        
    }
    
    public func showOPMLInterface(from sender: Any?, type: ShowOPMLType) {
        
        #if targetEnvironment(macCatalyst)
        openScene(name: "opmlScene:\(type.rawValue)")
        #else
        
        let vc = OPMLVC(nibName: "OPMLVC", bundle: Bundle.main)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .automatic
        
        let presenter: UIViewController = sender as? UIViewController ?? self.splitVC!
        
        presenter.present(nav, animated: true) {
            
            if type == .Export {
                vc.didTapExport(nil)
            }
            else if type == .Import {
                vc.didTapImport(nil)
            }
            
        }
        #endif
        
    }
    
    public func showContactInterface() {
        
        let attachment = DZMessagingAttachment()
        attachment.fileName = "debugInfo.txt"
        attachment.mimeType = "text/plain"
        
        let device = UIDevice.current.name
        let iOSVersion = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        let deviceID = FeedsManager.shared.deviceID ?? "0"
        
        let appVersion = FeedsManager.shared.fullVersion
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "0"
        
        let formatted = "Model: \(device) \(iOSVersion)\nDevice UUID: \(deviceID)\nAccount ID: \(DBManager.shared.user!.uuid ?? "0")\nApp: \(appVersion) (\(buildNumber))"
        
        attachment.data = formatted.data(using: .utf8) ?? Data()
        
        DZMessagingController.shared().delegate = self
        
        DZMessagingController.presentEmail(withBody: "", subject: "Elytra Support", recipients: ["support@elytra.app"], from: self.splitVC!)
        
    }
    
    public func showFeedInfo (feed: Feed, from: UIViewController, completion: (() -> Void)?) {
        
        let vc = FeedInfoController(feed: feed)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        from.present(nav, animated: true, completion: completion)
        
    }
    
    public func showFolderInfo() {
        
        // only works if the feed Info is already being presented
        
        if let feedInfo = (self.splitVC.presentedViewController as? UINavigationController)?.topViewController as? FeedInfoController {
            
            let indexPath = IndexPath(row: 0, section: 3)
            feedInfo.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            feedInfo.tableView(feedInfo.tableView, didSelectRowAt: indexPath)
            
        }
        
        
    }
    
    public func imageForSortingOption(_ option: FeedSorting) -> UIImage {
        
        return UIImage(systemName: FeedVC.imageNameForSortingOption(option: option))!
        
    }
    
    #if targetEnvironment(macCatalyst)
    
    public func showAttributions() {
        
        openScene(name: "attributionsScene")
        
    }
    
    #endif
    
    // MARK: - Resync
    public func prepareForFullResync() {
        
        DBManager.shared.purgeDataForResync { [weak self] in
            
            self?.sidebarVC?.resetSync()
            
        }
        
    }
    
    public func prepareForFeedsResync() {
        
        DBManager.shared.purgeFeedsForResync { [weak self] in
            
            self?.sidebarVC?.resetSync()
            
        }
        
    }
    
    // MARK: - Helpers
    var innerWindow: NSObject?
    
    public func showSupplementaryController(_ controller: UIViewController) {
        
        #if targetEnvironment(macCatalyst)
        
        if innerWindow == nil {
            
            var nsWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.nsWindow
            
            if nsWindow == nil {
                
                // try again in 1s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    
                    nsWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.nsWindow
                    
                    if nsWindow != nil {
                        
                        self?.innerWindow = nsWindow
                        
                        if self?.feedVC != nil {
                            self?.feedVC!.setupTitleView()
                        }
                        
                    }
                    
                }
                
            }
            else {
                self.innerWindow = nsWindow
            }
            
        }
        
        #endif
        
        if controller is FeedVC {
            self.feedVC = (controller as! FeedVC)
        }
        
        if (controller is UINavigationController) == false {
            
            controller.coordinator = self
            
        }
        
        guard let splitVC = self.splitVC else {
            return
        }
        
        if splitVC.traitCollection.horizontalSizeClass == .regular,
           splitVC.traitCollection.userInterfaceIdiom != .phone {
            
            if controller is UINavigationController {
                
                splitVC.setViewController(controller, for: .supplementary)
                
            }
            else {
                
                let nav = UINavigationController(rootViewController: controller)
                
                splitVC.setViewController(nav, for: .supplementary)
                
            }
            
            if splitVC.traitCollection.userInterfaceIdiom == .pad,
               splitVC.view.bounds.width < splitVC.view.bounds.height {
                
                splitVC.show(.primary)
                splitVC.show(.supplementary)
                
            }
            
        }
        
        else if let nav: UINavigationController = splitVC.viewControllers.first as? UINavigationController {
            
            nav.pushViewController(controller, animated: true)
            
        }
        
        #if targetEnvironment(macCatalyst)
        if controller is FeedVC,
           let scene = MyAppDelegate.mainScene?.delegate as? SceneDelegate {
            
            if let toolbarItem: NSToolbarItem = scene.toolbar?.items.first(where: { $0.itemIdentifier.rawValue == "com.yeti.toolbar.sortingMenu" }) {
                toolbarItem.validate()
            }
            
        }
        #endif
        
    }
    
    public func showDetailController(_ controller: UIViewController) {
        
        let isEmptyVC: Bool = controller is EmptyVC
        
        if isEmptyVC == true {
            self.emptyVC = (controller as! EmptyVC)
        }
        
        guard let splitVC = self.splitVC else {
            return
        }
        
        if splitVC.presentedViewController != nil,
           let nav = splitVC.presentedViewController as? UINavigationController {
         
            nav.pushViewController(controller, animated: false)
            
        }
        else if splitVC.traitCollection.horizontalSizeClass == .regular {
            
            let nav = UINavigationController(rootViewController: controller)
            
            splitVC.setViewController(nav, for: .secondary)
            
        }
        else {
            
            // We never push the empty VC on the navigation stack on compact devices.
            
            if isEmptyVC {
                self.emptyVC = nil
                return
            }
            
            if let nav = splitVC.viewControllers.first as? UINavigationController {
                
                nav.pushViewController(controller, animated: true)
                
            }
            
        }
        
        if (controller is ArticleVC) == false, splitVC.traitCollection.userInterfaceIdiom == .pad {
            
            if splitVC.isCollapsed == false,
               splitVC.displayMode == .twoDisplaceSecondary {
                
                DispatchQueue.main.async {
                    
                    splitVC.preferredDisplayMode = .oneBesideSecondary
                    
                }
                
            }
            
        }
        
    }
    
    public func openScene(name: String) {
        
        let options = UIScene.ActivationRequestOptions()
        options.requestingScene = splitVC?.view.window?.windowScene
        #if targetEnvironment(macCatalyst)
        options.collectionJoinBehavior = .disallowed
        #endif
        
        let activity = NSUserActivity(activityType: name)
        
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: options) { error in
            
            print("Error occurred requesting new window session. \(error.localizedDescription)")
            
        }
        
    }
    
    // MARK: - Push Notifications
    
    public func checkForPushNotifications() {
        
        guard Thread.isMainThread == true else {
            
            performSelector(onMainThread: #selector(Coordinator.checkForPushNotifications), with: nil, waitUntilDone: false)
            
            return
        }
        
        let didAsk: Bool = Defaults[.pushRequest]
        
        guard didAsk == false else {
            return
        }
        
        guard let u = FeedsManager.shared.user,
              let _ = u.userID else {
            return
        }
        
        guard UIApplication.shared.applicationState == UIApplication.State.active else {
            return
        }
        
        guard UIApplication.shared.isRegisteredForRemoteNotifications == false else {
            registerForNotifications(completion: nil)
            return
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (settings) in
            
            guard let sself = self else { return }
            
            if settings.authorizationStatus == .denied {
                // no permission, ignore.
            }
            else if settings.authorizationStatus == .notDetermined {
                
                dispatchMainAsync {
                    
                    let vc = PushRequestVC(nibName: "PushRequestVC", bundle: Bundle.main)
                    vc.coordinator = self
                    vc.modalPresentationStyle = .overFullScreen
                    
                    sself.splitVC?.present(vc, animated: true, completion: nil)
                    
                }
                
            }
            else {
                sself.registerForNotifications(completion: nil)
            }
            
        }
        
    }
    
    public func didTapCloseForPushRequest() {
        
        Defaults[.pushRequest] = true
        
    }
    
    var registerNotificationsTimer :Timer?
    
    public func registerForNotifications(completion: ((_ error: Error?, _ completed: Bool) -> Void)?) {
        
        let isImmediate: Bool = Thread.callStackSymbols.description.contains("PushRequestVC")
        
        runOnMainQueueWithoutDeadlocking { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            guard UIApplication.shared.applicationState == .active else {
                
                completion?(nil, false)
                
                return
            }
            
            guard UIApplication.shared.isRegisteredForRemoteNotifications == false else {
                completion?(nil, true)
                return
            }
            
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                
                switch settings.authorizationStatus {
                case .denied:
                    completion?(nil, false)
                case .authorized:
                    completion?(nil, true)
                case .notDetermined:
                    
                    if sself.registerNotificationsTimer != nil {
                        sself.registerNotificationsTimer?.invalidate()
                        sself.registerNotificationsTimer = nil
                    }
                    
                    let interval: TimeInterval = isImmediate ? 0 : 2
                    
                    runOnMainQueueWithoutDeadlocking {
                        
                        sself.registerNotificationsTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { _ in
                            
                            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                                
                                if error != nil {
                                    completion?(error, false)
                                    return
                                }
                                
                                if granted {
                                    
                                    Keychain.add(kIsSubscribingToPushNotifications, boolean: true)
                                    
                                    DispatchQueue.main.async {
                                        
                                        UIApplication.shared.registerForRemoteNotifications()
                                        
                                    }
                                    
                                }
                                
                                DispatchQueue.main.async {
                                    completion?(nil, granted)
                                }
                                
                            }
                            
                        })
                        
                    }
                    
                default:
                    print("Unhandled notification settings state \(settings.authorizationStatus)")
                }
                
            }
            
        }
        
    }
    
    // MARK: - Review
    var shouldRequestReview: Bool = false
    
    public func checkConstraintsForRequestingReview() {
        
        guard shouldRequestReview == false else {
            return
        }
        
        let fullVersion = FeedsManager.shared.fullVersion
        
        var error: NSError?
        var count = Keychain.integer(for: "launchCount-\(fullVersion)", error: &error)
        
        if error != nil {
            count = 1
        }
        
        Keychain.add("launchCount-\(fullVersion)", integer: count + 1)
        
        if count > 6 {
            // request review on the 7th launch
            shouldRequestReview = Keychain.bool(for: "requestedReview-\(fullVersion)") == false
        }
        
    }
    
    // MARK: - Shared Containers
    var sharedContainerURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra")!
    
    public func writeTo(sharedFile: String, data: Data) {
        
        guard data.count > 0 else {
            return
        }
        
        let fileURL: URL = sharedContainerURL.appendingPathComponent(sharedFile)
        
        let fm = FileManager.default
        
        let path = fileURL.standardizedFileURL.path
        
        if fm.fileExists(atPath: path) {
            // remove the existing file
            
            do { try fm.removeItem(atPath: path) }
            catch {
                print(error)
                return
            }
            
        }
        
        if (data as NSData).write(toFile: path, atomically: true) == false {
            print("Failed to write data to \(path)")
        }
        else {
            print("Updated shared file \(sharedFile)")
        }
        
    }

}

// MARK: - Background Push

extension Coordinator {
    
    func updateSubscription(_ completion: ((_ result: UIBackgroundFetchResult) -> Void)?) {
        
        FeedsManager.shared.getSubscription { result in
            
            switch result {
            
            case .failure(let error):
                print("error updating subscription in background: \(error)")
                completion?(.failed)
                
            case .success(let sub):
                let user = DBManager.shared.user
                user?.subscription = sub
                DBManager.shared.user = user
                
                completion?(.newData)
            }
            
        }
        
    }
    
    func getArticle(_ articleID: String, completion: ((_ result: UIBackgroundFetchResult) -> Void)?) {
        
        FeedsManager.shared.getArticle(articleID) { result in
            
            switch result {
            
            case .failure(let error):
                print("error fetching article \(articleID) in background: \(error)")
                completion?(.failed)
                
            case .success(let article):
                DBManager.shared.add(article: article, strip: true)
                
                completion?(.newData)
            }
            
        }
        
    }
    
}

// MARK: - Briding DBManager and FeedsManager
extension Coordinator {
    
    public var user: User? {
        get {
            return DBManager.shared.user
        }
        set {
            DBManager.shared.user = newValue
        }
    }
    
    public func processUUID(uuid: String, completion:((_ error: Error?, _ user: User?) -> Void)?) {
    
        print("Got \(uuid)")
        
        FeedsManager.shared.getUser(userID: uuid) { [weak self] (result) in
            
            guard let sself = self else {
                completion?(nil, nil)
                return
            }
            
            switch result {
            case .failure(let error as NSError):
                
                if error.code == 404 || error.localizedDescription.contains("User not found") {
                    
                    // create the user
                    FeedsManager.shared.createUser(uuid: uuid) { (result) in
                        
                        switch result {
                        case .failure(let error as NSError):
                            completion?(error, nil)
                            AlertManager.showGenericAlert(withTitle: "Creating Account Failed", message: error.localizedDescription)
                            
                        case .success(let u):
                            sself.setupUser(u, existing: false)
                            completion?(nil, u)
                        }
                        
                    }
                    
                    return
                    
                }
                
                AlertManager.showGenericAlert(withTitle: "Error Logging In", message: error.localizedDescription)
                
            case .success(let u):
                
                sself.setupUser(u, existing: true)
                completion?(nil, u)
                
            }
            
        }
    
    }
    
    func setupUser(_ u: User?, existing: Bool = false) {
        
        guard let user = u else {
            AlertManager.showGenericAlert(withTitle: "Error Logging In", message: "No user information received for your account")
            return
        }
        
        DBManager.shared.user = user
        FeedsManager.shared.user = DBManager.shared.user
        
    }
    
    // MARK: - Account
    public func setPushToken(token: String) {
        FeedsManager.shared.pushToken = token
    }
    
    public func getSubscription(completion:((_ error: Error?) -> Void)?) {
        
        FeedsManager.shared.getSubscription { result in
            
            switch result {
            case .failure(let error):
                print("Error fetching subscription", error)
                completion?(error)
            case .success(let subscription):
                let user: User = DBManager.shared.user!
                user.subscription = subscription
                
                DBManager.shared.user = user
                completion?(nil)
            }
            
        }
        
    }
    
    public func resetAccount(completion: (() -> Void)?) {
        
        DBManager.shared.resetAccount(completion: completion)
        
    }
    
    public func deactivateAccount(completion: ((_ status: Bool, _ error: Error?) -> Void)?) {
        
        FeedsManager.shared.deactivateAccount { result in
            
            switch result {
            case .failure(let error):
                completion?(false, error)
                
            case .success(let status):
                completion?(status, nil)
            }
            
        }
        
    }
    
    public func postAppReceipt(receipt: Data, completion:((_ subscription: Models.Subscription?, _ error: Error?) -> Void)?) {
        
        FeedsManager.shared.postAppReceipt(receipt) { result in
            
            switch result {
            
            case .failure(let error):
                completion?(nil, error)
            
            case .success(let result):
                
                if let user = DBManager.shared.user {
                    user.subscription = result
                    DBManager.shared.user = user
                }
                
                completion?(result, nil)
            }
            
        }
        
    }
    
    // MARK: - Feeds
    
    public func showAddingFeedDialog() {
        
        if let avc = AlertManager.showActivity(title: "Adding Feed") {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                
                avc.dismiss(animated: true, completion: nil)
                
            }
            
        }
        
    }
    
    public func addFeed(url: URL) {
        
        let json: [String: AnyHashable] = [
            "id": "feed/\(url.absoluteString)",
            "feedId": "feed/\(url.absoluteString)"
        ]
     
        addFeed(json: json, folderID: nil, completion: nil)
        
    }
    
    public func addFeed(_ djson: [String: AnyHashable], folderID: UInt, completion:((_ feed: Feed?, _ error: Error?) -> Void)?) {
        
        addFeed(json: djson, folderID: folderID) { result in
            
            switch result {
            case .failure(let error):
                completion?(nil, error)
                
            case .success(let feed):
                completion?(feed, nil)
            }
            
        }
        
    }
    
    public func addFeed(json: [String: AnyHashable], folderID: UInt?, completion: ((Result<Feed, Error>) -> Void)?) {
        
        guard var feedID: String = (json["feedId"] ?? json["id"]) as? String else {
            completion?(.failure(FeedsManagerError.from(description: "This feed does not have a URL representation.", statusCode: 400)))
            return
        }
        
        feedID = feedID.replacingOccurrences(of: "feed/", with: "")
        
        guard let url = URL(string: feedID) else {
            completion?(.failure(FeedsManagerError.from(description: "This feed does not have a valid URL representation.", statusCode: 400)))
            return
        }
        
        let have: Feed? = DBManager.shared.feeds.first(where: { $0.url == url })
        
        guard have == nil else {
            
            completion?(.failure(FeedsManagerError.from(description: "This feed already exists in your list.", statusCode: 304)))
            return
            
        }
        
        if importingInProgress == false {
            showAddingFeedDialog()
        }
        
        if url.absoluteString.contains("youtube.com") == true,
           url.absoluteString.contains("videos.xml") == false {
            
            FeedsManager.shared.checkYoutube(url: url) { [weak self] result in
                
                switch result {
                case .failure(let error):
                    completion?(.failure(FeedsManagerError.from(description:  "An error occurred when trying to process the Youtube URL: \(error.localizedDescription)", statusCode: 500)))
                    
                case .success(let finalURL):
                    let json: [String: AnyHashable] = [
                        "id": "feed/\(finalURL.absoluteString)",
                        "feedId": "feed/\(finalURL.absoluteString)"
                    ]
                    
                    self?.addFeed(json: json, folderID: folderID, completion: completion)
                }
                
            }
            
            return
            
        }
        
        FeedsManager.shared.add(feed: json) { [weak self] result in
            
            guard let sself = self else {
                return
            }
            
            switch result {
            case .failure(let error):
                
                Haptics.shared.generate(feedbackType: .notificationError)
                
                AlertManager.showGenericAlert(withTitle: "Error Processing", message: "An error occurred when trying to process the Youtube URL: \(error.localizedDescription)")
                
                completion?(.failure(error))
                
            case .success(let feed):
                
                let first: Feed? = DBManager.shared.feeds.first(where: { $0.feedID == feed.feedID })
                
                if first == nil {
                    
                    Haptics.shared.generate(feedbackType: .notificationSuccess)
                    
                    DBManager.shared.feeds.append(feed)
                    
                    DispatchQueue.global(qos: .default).async { [weak self] in
                        self?.syncAdditionalFeed(feed)
                    }
                    
                    let hasAddedFirst = Keychain.bool(for: YTSubscriptionHasAddedFirstFeed)
                    
                    if hasAddedFirst == false {
                        Keychain.add(YTSubscriptionHasAddedFirstFeed, boolean: true)
                    }
                    
                    // Trigger update
                    if (folderID == nil) {
                        CoalescingQueue.standard.add(sself.sidebarVC, #selector(SidebarVC.setupData))
                    }
                    
                }
                else {
                    Haptics.shared.generate(feedbackType: .notificaitonWarning)
                    
                    AlertManager.showGenericAlert(withTitle: "Feed Exists", message: "This feed already exists in your list.")
                }
                
                if let folderID = folderID, folderID != 0 {
                    
                    // check if the folder exists
                    if let folder = DBManager.shared.folder(for: folderID) {
                        
                        // check if the folder already contains this feed
                        if folder.feedIDs.contains(feed.feedID) == false {
                            
                            // update the folder struct
                            FeedsManager.shared.update(folder: folderID, title: nil, add: [feed.feedID], delete: nil) { result in
                                
                                completion?(.success(feed))
                                
                                CoalescingQueue.standard.add(sself.sidebarVC, #selector(SidebarVC.setupData))
                                
                                if case .success(let status) = result,
                                   status == true {
                                    
                                    folder.feedIDs.append(feed.feedID)
                                    // trigger Update
                                    DBManager.shared.folders = DBManager.shared.folders
                                    
                                }
                                
                            }
                            
                            return
                            
                        }
                        
                    }
                    
                }
                
                completion?(.success(feed))
            
            }
            
        }
        
    }
    
    public func addFeed(id: UInt) {
        
        let have: Feed? = DBManager.shared.feeds.first(where: { $0.feedID == id })
        
        guard have == nil else {
            
            AlertManager.showGenericAlert(withTitle: "Feed Exists", message: "This feed already exists in your list.")
            return
            
        }
        
        FeedsManager.shared.add(feed: id) { result in
            
            switch result {
            case .failure(let error):
                
                Haptics.shared.generate(feedbackType: .notificationError)
                
                AlertManager.showGenericAlert(withTitle: "Error Processing", message: "An error occurred when trying to process the Youtube URL: \(error.localizedDescription)")
                
            case .success(let feed):
                
                // check if we have the feed
                let first: Feed? = DBManager.shared.feeds.first(where: { $0.feedID == feed.feedID })
                
                guard first == nil else {
                    
                    Haptics.shared.generate(feedbackType: .notificationSuccess)
                    
                    DBManager.shared.feeds.append(feed)
                    
                    DispatchQueue.global(qos: .default).async { [weak self] in
                        self?.syncAdditionalFeed(feed)
                    }
                    
                    let hasAddedFirst = Keychain.bool(for: YTSubscriptionHasAddedFirstFeed)
                    
                    if hasAddedFirst == false {
                        Keychain.add(YTSubscriptionHasAddedFirstFeed, boolean: true)
                    }
                    
                    return
                }
                
                Haptics.shared.generate(feedbackType: .notificaitonWarning)
                
                AlertManager.showGenericAlert(withTitle: "Feed Exists", message: "This feed already exists in your list.")
            
            }
            
        }
        
    }
    
    public func rename(feed: Feed, title: String, completion:((Bool) -> Void)?) {
        
        FeedsManager.shared.rename(feed: feed.feedID, title: title) { result in
            
            switch result {
            case .failure(let error):
                
                AlertManager.showGenericAlert(withTitle: "Error Renaming", message: error.localizedDescription)
                completion?(false)
                
            case .success(let status):
                
                if (status == true) {
                        
                    DBManager.shared.rename(feed: feed, customTitle: title) { (result) in
                        
                        switch result {
                        case .failure(let err):
                            AlertManager.showGenericAlert(withTitle: "Error Renaming", message: err.localizedDescription)
                            completion?(false)
                            
                        case .success:
                            
                            completion?(true)
                            
                        }
                        
                    }
                    
                }
                else {
                    completion?(false)
                }
                                
            }
            
        }
        
    }
    
    public func syncAdditionalFeed(_ feed: Feed) {
        
        guard let feedID = feed.feedID else {
            print("No feedID on feed: \(feed). Exiting additional sync.")
            return
        }
        
        syncAdditionalFeed(feedID, page: 1)
        
    }
    
    public func syncAdditionalFeed(_ feedID: UInt, page: UInt = 1) {
        
        FeedsManager.shared.getArticles(forFeed: feedID, page: page) { [weak self] result in
            
            switch result {
            
            case .failure(let error):
                print("Error fetching articles for feed: \(feedID), page: \(page)\n\(error)")
            
            case .success(let articles):
                
                DBManager.shared.add(articles: articles, strip: true)
                
                // up to maximum of 5 pages (or 100 Articles)
                if articles.count == 20 && page < 5 {
                    // fetch the next page
                    self?.syncAdditionalFeed(feedID, page: page + 1)
                }
                
            }
            
        }
        
    }
    
    // MARK: - Folders
    public func folder(with title:String) -> Folder? {
        
        return DBManager.shared.folders.first(where: { $0.title == title })
        
    }
    
    public func removeFromFolder(_ feed: Feed, folder: Folder, completion: ((Result<Bool, Error>) -> Void)?) {
        
        FeedsManager.shared.update(folder: folder.folderID, title: nil, add: nil, delete: [feed.feedID]) { result in
            
            switch result {
            
            case .failure(let error):
                completion?(.failure(error))
            
            case .success(let status):
                
                if status == true {
                    feed.folderID = nil
                    DBManager.shared.update(feed: feed)
                    
                    folder.feedIDs = folder.feedIDs.filter { $0 != feed.feedID }
                    folder.feeds = OrderedSet<Feed>(folder.feeds.filter { $0.feedID != feed.feedID })
                    
                    DBManager.shared.update(folder: folder)
                    
                }
                
                completion?(.success(status))
            
            }
            
        }
        
    }
    
    public func addToFolder(_ feed: Feed, folder: Folder, completion: ((Result<Bool, Error>) -> Void)?) {
        
        FeedsManager.shared.update(folder: folder.folderID, title: nil, add: [feed.feedID], delete: nil) { result in
            
            switch result {
            
            case .failure(let error):
                completion?(.failure(error))
            
            case .success(let status):
                
                if status == true {
                    feed.folderID = folder.folderID
                    DBManager.shared.update(feed: feed)
                    
                    folder.feedIDs.append(feed.feedID)
                    folder.feeds.append(feed)
                    
                    DBManager.shared.update(folder: folder)
                    
                }
                
                completion?(.success(status))
            
            }
            
        }
        
    }
    
    public func renameFolder(_ folder: Folder, title: String, completion: ((_ status: Bool, _ error: Error?) -> Void)?) {
        
        FeedsManager.shared.update(folder: folder.folderID, title: title, add: nil, delete: nil) { result in
            
            switch result {
            
            case .failure(let error):
                completion?(false, error)
            
            case .success(let status):
                
                if status == true {
                    
                    folder.title = title
                    
                    DBManager.shared.update(folder: folder)
                    
                }
                
                completion?(status, nil)
            
            }
            
        }
        
    }
    
    public func addFolder(title: String, completion: ((_ folder: Folder?, _ error: Error?) -> Void)?) {
        
        FeedsManager.shared.add(folder: title) { result in
            
            switch result {
            case .failure(let error):
                completion?(nil, error)
                
            case .success(let folder):
                
                DBManager.shared.add(folder: folder)
                
                completion?(folder, nil)
            }
            
        }
        
    }
    
    public func delete(folder: Folder, completion: ((_ status: Bool, _ error: Error?) -> Void)?) {
     
        FeedsManager.shared.delete(folder: folder.folderID) { result in
            
            switch result {
            case .failure(let error):
                completion?(false, error)
                
            case .success(let status):
                
                if status == true {
                    DBManager.shared.delete(folder: folder)
                }
                
                completion?(status, nil)
            }
            
        }
        
    }
    
    // MARK: - Articles
    public func deleteFullText(for article: Article) {
        
        DBManager.shared.delete(fullTextFor: article.identifier)
        
    }
    
    // MARK: - WebSub
    public func getAllWebSub(completion: ((_ feeds: [Feed]?, _ error: Error?) -> Void)?) {
        
        FeedsManager.shared.getAllWebSub { result in
            
            switch result {
            case .failure(let error):
                completion?(nil, error)
                
            case .success(let feeds):
                completion?(feeds, nil)
            }
            
        }
        
    }
    
    public func unsubscribe(_ feed: Feed, completion: ((_ status: Bool, _ error: Error?) -> Void)?) {
        
        FeedsManager.shared.unsubscribe(feed) { result in
            
            switch result {
            case .failure(let error):
                completion?(false, error)
                
            case .success(let status):
                completion?(status, nil)
            }
            
        }
        
    }
    
    // MARK: - Migrated from MyFeedsManager
    // MARK: - User
    public func startFreeTrial(u: User?, completion: ((_ error: Error?, _ success: Bool) -> Void)?) {
        
        FeedsManager.shared.startFreeTrial { result in
            
            switch result {
            case .success(let sub):
                
                guard let user = DBManager.shared.user else {
                    completion?(nil, true)
                    return
                }
                
                user.subscription = sub
                
                DBManager.shared.user = user
                
                completion?(nil, true)
                
            case .failure(let error):
                completion?(error, false)
                
            }
            
        }
        
    }
    
    // MARK: - Feeds & Articles
    
    public func feedFor(_ id: UInt) -> Feed? {
        
        return DBManager.shared.feed(for: id)
        
    }
    
    public func metadataFor(feed:Feed) -> FeedMeta? {
        
        return DBManager.shared.metadataForFeed(feed)
        
    }
    
    public func getContentFromDB(_ article: String) -> [Content]? {
        
        return DBManager.shared.content(for: article)
        
    }
    
    public func getFullTextFromDB(_ article: String) -> [Content]? {
        
        return DBManager.shared.fullText(for: article)
        
    }
    
    public func getFullText(_ article: Article, completion: ((_ error: Error?, _ fullText: Article?) -> Void)?) {
        
        if let fullText = DBManager.shared.fullText(for: article.identifier) {
            
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
    
    public func getArticle(_ id: String, feedID: UInt, completion: ((_ error: Error?, _ article: Article?) -> Void)?) {
        
        getArticle(id, feedID: feedID, reload: false, completion: completion)
        
    }
    
    public func getArticle(_ id: String, feedID: UInt, reload: Bool = false, completion: ((_ error: Error?, _ article: Article?) -> Void)?) {
        
        if reload == false,
           let article = DBManager.shared.article(for: id, feedID: feedID) {
            
            if article.content.count == 0 {
                
                // check if full text is loaded
                if let fulltext = DBManager.shared.fullText(for: article.identifier) {
                    article.content = fulltext
                    article.fulltext = true
                }
                else if let content = DBManager.shared.content(for: article.identifier) {
                    article.content = content
                    article.fulltext = false
                }
                
            }
            
            if article.content.count > 0 {
                completion?(nil, article)
                return
            }
            
        }
        
        FeedsManager.shared.getArticle(id) { result in

            switch result {
            case .failure(let error):
                completion?(error, nil)
                
            case .success(let article):
                DBManager.shared.add(article: article, strip: false)
                completion?(nil, article)
            }
            
        }
        
    }
    
    public func purgeForFullResync (completion: (() -> Void)?) {
        
        DBManager.shared.purgeDataForResync(completion: completion)
        
    }
    
    public func purgeForFeedResync (completion: (() -> Void)?) {
        
        DBManager.shared.purgeFeedsForResync(completion: completion)
        
    }
    
    public func getFilters(completion: ((_ error: Error?, _ filters: [String]?) -> Void)?) {
     
        FeedsManager.shared.getFilters { result in
            
            switch result {
            case .failure(let error):
                completion?(error, nil)
                
            case .success(let filters):
                completion?(nil, filters)
            }
            
        }
        
    }
    
    public func addFilter(text: String, completion: ((_ error: Error?, _ status: Bool) -> Void)?) {
        
        FeedsManager.shared.addFilter(text) { result in
            
            switch result {
            case .failure(let error):
                completion?(error, false)
            
            case .success(let status):
                completion?(nil, status)
            }
            
        }
        
    }
    
    public func deleteFilter(text: String, completion: ((_ error: Error?, _ status: Bool) -> Void)?) {
        
        FeedsManager.shared.deleteFilter(text) { result in
            
            switch result {
            case .failure(let error):
                completion?(error, false)
            
            case .success(let status):
                completion?(nil, status)
            }
            
        }
        
    }
    
    public func setBackgroundCompletionBlock(completion: (() -> Void)?) {
        
        FeedsManager.shared.backgroundSession.backgroundCompletionHandler = completion
        
    }
    
    public func setupBGSyncCoordinator(task: BGAppRefreshTask, completion: ((Bool) -> Void)?) {
        
        guard DBManager.shared.syncCoordinator == nil else {
            task.setTaskCompleted(success: false)
            completion?(false)
            return
        }
        
        let syncCoordinator: SyncCoordinator = SyncCoordinator()
        
        DBManager.shared.syncCoordinator = syncCoordinator
        
        syncCoordinator.setupSync(with: task) { completed in
            
            if (completed) {
                DBManager.shared.lastUpdated = Date()
            }
            
            completion?(completed)
            
        }
        
    }
    
    public func setupBGCleanup(task: BGProcessingTask) {
        
        DBManager.shared.cleanupDatabase(completion: {
            task.setTaskCompleted(success: true)
        })
        
    }
    
    public func completedBGSync() {
        
        DBManager.shared.syncCoordinator = nil
        
    }
    
    // MARK: - Widgets
    @objc func updateSharedUnreadsData() {
        
        guard (
                WidgetManager.usingUnreadsWidget == true
                    || WidgetManager.usingBloccsWidget == true
                    || WidgetManager.usingFoldersWidget == true) else {
            return
        }
            
        DBManager.shared.uiConnection.asyncRead { [weak self] (t) in
            
            guard let sself = self else { return }
            
            guard let txn = t.ext(DBManagerViews.unreadsView.rawValue) as? YapDatabaseFilteredViewTransaction else {
                return
            }
            
            var items: [Article] = []
            
            txn.enumerateKeysAndObjects(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, 20)) { (_, _) -> Bool in
                return true
            } using: { (c, key, object, index, stop) in
                
                guard let item = object as? Article else {
                    return
                }
                
                items.append(item)
                
            }

            DBManager.shared.writeQueue.async { [weak self] in
                
                var usableItems: [Article] = items
                
                self?.updateSharedBloccsData(items: usableItems, t: t)
                
                let upperBound = max(0, min(4, usableItems.count))
                usableItems = Array(usableItems[0..<upperBound])
                
                let list = self?.widgetItemsToList(usableItems, t: t)
                
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(list) {
                    
                    sself.writeTo(sharedFile: "articles.json", data: data)
                    
                }
                
            }
            
        }
        
    }
    
    func updateSharedBloccsData (items: [Article], t: YapDatabaseReadTransaction) {
        
        guard WidgetManager.usingBloccsWidget == true else {
            return
        }
        
        var usableItems: [Article] = items
        
        let coverItems = items.filter { $0.coverImage != nil }
        let max: Int = 6
        let total = coverItems.count
        
        let upperLimit = min(max, total)
        
        usableItems = Array(coverItems[0..<upperLimit])
        
        let list = widgetItemsToList(usableItems, t: t)
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(list) {
            
            writeTo(sharedFile: "bloccs.json", data: data)
            
        }
        
    }
    
    func updateSharedFoldersArticles () {
        
        guard WidgetManager.usingFoldersWidget == true,
              WidgetManager.selectedFolder != nil else {
            return
        }
        
        guard let fIDString = WidgetManager.selectedFolder?.identifier as NSString? else {
            return
        }
        
        let folderID = UInt(fIDString.integerValue)
        
        DBManager.shared.countsConnection.asyncRead { [weak self] t in
            
            guard let sself = self else { return }
            
            // get all items from the specific folder
            guard let txn = t.ext(DBManagerViews.articlesView.rawValue) as? YapDatabaseFilteredViewTransaction else {
                return
            }
            
            var hasOneCover: Bool = false
            var items: [Article] = []
            
            let end = txn.numberOfItems(inGroup: GroupNames.articles.rawValue)
            
            txn.enumerateKeysAndObjects(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, Int(end))) { (_, _) -> Bool in
                return true
            } using: { (c, key, object, index, stop) in
                
                guard let item = object as? Article else {
                    return
                }
                
                guard let feed = DBManager.shared.feed(for: item.feedID),
                      feed.folderID != nil else {
                    return
                }
                
//                print(folderID, feed.folderID ?? 0)
                
                if (feed.folderID! == folderID) {
                    
                    // covers are also important here.
                    if (hasOneCover == false && item.coverImage != nil) {
                        hasOneCover = true
                        items.append(item)
                    }
                    else {
                        items.append(item)
                    }
                    
                    if (items.count == 6) {
                        stop.pointee = true
                    }
                    
                }
                
            }
            
            let list = sself.widgetItemsToList(items, t: t)
            
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(list) {
                
                sself.writeTo(sharedFile: "foldersW.json", data: data)
                
                print("Updated folder articles data")
                
            }
            
        }
        
    }
    
    func widgetItemsToList(_ usableItems: [Article], t: YapDatabaseReadTransaction) -> [WidgetArticle] {
        
        // Actually stores WidgetArticle before writing to disk.
        var widgetList: [WidgetArticle] = []
        
        if usableItems.count > 0 {
            
            let list: [Article] = usableItems
            
            widgetList = list.map { WidgetArticle.init(copyFrom: $0) }
            
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
            
        }
        
        return widgetList
        
    }
    
    public func updateSharedFoldersData() {
        
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else { return }
            
            let folders = DBManager.shared.folders
            
            guard folders.count > 0 else {
                return
            }
            
            let structs: [WidgetFolder] = folders.map { WidgetFolder(title: $0.title, folderID: $0.folderID) }
            
            if let data = try? JSONEncoder().encode(structs) {
                
                self.writeTo(sharedFile: "folders.json", data: data)
                
            }
            
        }
        
    }
    
    // MARK: - Accessors
    @objc var session: DZURLSession {
        return FeedsManager.shared.session
    }
    
    @objc public func getOPML(completion:@escaping ((_ xmlData: String?, _ error: Error?) -> Void)) {
     
        FeedsManager.shared.getOPML(completion: completion)
        
    }
    
    @objc public func getFeedLibsData(url: URL, completion: @escaping ((_ result: [String: Any]?, _ error: Error?) -> Void)) {
        
        FeedsLib.shared.getFeedInfo(url: url) { error, response in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let results = response?.results,
               results.count > 0 {
                
                let result: FeedRecommendation = results.first!
                
                let encoder = JSONEncoder()
                guard let data = try? encoder.encode(result),
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyHashable] else {
                 
                    completion(nil, FeedsManagerError.from(description: "No feeds were found for this URL", statusCode: 500))
                    return
                    
                }
                
                completion(json, nil)
                
            }
            else {
                completion(nil, FeedsManagerError.from(description: "No feeds were found for this URL", statusCode: 500))
            }
            
        }
        
    }
    
    // MARK: - MacOS
    public func showPanel() {
        
        let panel = Dynamic.NSPanel()
        panel.beginSheetModalForWindow(splitVC.view.window!.nsWindow, completionHandler: { response in
            if let url: URL = panel.URLs.firstObject {
                print("url: ", url)
            }
        } as ResponseBlock)

        typealias ResponseBlock = @convention(block) (_ response: Int) -> Void
        
    }
    
}

extension UIWindow {
    var nsWindow: NSObject? {
        var nsWindow = Dynamic.NSApplication.sharedApplication.delegate.hostWindowForUIWindow(self)
        if #available(macOS 11, *) {
            nsWindow = nsWindow.attachedWindow
        }
        return nsWindow.asObject
    }
}

extension Coordinator: DZMessagingDelegate {
    
    public func emailWasCancelledOrFailed(toSend error: Error?) {
        
        DZMessagingController.shared().delegate = nil
        
        guard error != nil else {
            return
        }
        
        
        
    }
    
    public func userDidSendEmail() {
        
        DZMessagingController.shared().delegate = nil
        
    }
    
}
