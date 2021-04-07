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
import Dynamic
import Models
import DBManager
import DZKit
import DeviceCheck
import Combine

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
    
    weak public var activityDialog: UIAlertController?
    
    var cancellables: [AnyCancellable] = []
    
    public func start(_ splitViewController: SplitVC) {
        
        setupDeviceID()
        
        self.splitVC = splitViewController
        splitViewController.coordinator = self
        
        let sidebar = SidebarVC()
        sidebar.coordinator = self
        
//        if splitVC?.traitCollection.userInterfaceIdiom == .phone {
//
//            let nav = UINavigationController(rootViewController: sidebar)
//            sidebar.navigationController?.navigationBar.prefersLargeTitles = true
//            sidebar.navigationItem.largeTitleDisplayMode = .automatic
//
//            splitVC?.setViewController(nav, for: .compact)
//
//        }
        
        splitVC.setViewController(sidebar, for: .primary)
        
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
                
                let f = CustomFeed(title: "Unread", image: "largecircle.fill.circle", color: .systemBlue, type: .unread)
                
                sself.showCustomVC(f)
            }
            
            if showEmpty {
                self?.showEmptyVC()
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
        
    }
    
    // MARK: - Feeds
    public func showCustomVC(_ feed: CustomFeed) {
        
        if feed.feedType == .unread && (self.feedVC == nil || (self.feedVC != nil && self.feedVC!.type != .unread)) {
            
            self.feedVC = nil
            
            let unread = UnreadVC(style: .plain)
            showSupplementaryController(unread)
            
        }
        else if feed.feedType == .today {
            
            let today = TodayVC(style: .plain)
            showSupplementaryController(today)
            
        }
        else if feed.feedType == .bookmarks {
            // @TODO
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
        
        if let splitVC = self.splitVC, splitVC.traitCollection.userInterfaceIdiom != .mac,
           splitVC.view.bounds.size.width < 1024 {
            
            dispatchMainAsync {
                
                splitVC.preferredDisplayMode = .secondaryOnly
                
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
        
        showDetailController(vc)
        
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
        
        let vc = OPMLVC(nibName: "OPMLVC", bundle: Bundle.main)
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
                            self?.feedVC?.setupTitleView()
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
            feedVC = (controller as! FeedVC)
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
            
            return
            
        }
        
        if let nav: UINavigationController = splitVC.viewControllers.first as? UINavigationController {
            
            nav.pushViewController(controller, animated: true)
            
        }
        
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
        
        if splitVC.traitCollection.userInterfaceIdiom == .pad {
            
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
            return
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (settings) in
            
            if settings.authorizationStatus == .denied {
                // no permission, ignore.
            }
            else if settings.authorizationStatus == .notDetermined {
                
                dispatchMainAsync {
                    
                    let vc = PushRequestVC(nibName: "PushRequestVC", bundle: Bundle.main)
                    vc.coordinator = self
                    vc.modalPresentationStyle = .overFullScreen
                    
                    guard let sself = self else { return }
                    
                    sself.splitVC?.present(vc, animated: true, completion: nil)
                    
                }
                
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
    
    // MARK: - Feeds
    
    public func showAddingFeedDialog() {
        
        if let avc = AlertManager.showActivity(title: "Adding Feed") {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                
                avc.dismiss(animated: true, completion: nil)
                
            }
            
        }
        
    }
    
    public func addFeed(url: URL) {
     
        addFeed(url: url, folderID: nil, completion: nil)
        
    }
    
    public func addFeed(url: URL, folderID: UInt?, completion: ((Result<Feed, Error>) -> Void)?) {
        
        let have: Feed? = DBManager.shared.feeds.first(where: { $0.url == url })
        
        guard have == nil else {
            
            completion?(.failure(FeedsManagerError.from(description: "This feed already exists in your list.", statusCode: 304)))
            return
            
        }
        
        showAddingFeedDialog()
        
        if url.absoluteString.contains("youtube.com") == true,
           url.absoluteString.contains("videos.xml") == false {
            
            FeedsManager.shared.checkYoutube(url: url) { [weak self] result in
                
                switch result {
                case .failure(let error):
                    completion?(.failure(FeedsManagerError.from(description:  "An error occurred when trying to process the Youtube URL: \(error.localizedDescription)", statusCode: 500)))
                    
                case .success(let finalURL):
                    self?.addFeed(url: finalURL)
                }
                
            }
            
            return
            
        }
        
        FeedsManager.shared.add(feed: url) { [weak self] result in
            
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
                
                if let folderID = folderID {
                    
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
                    folder.feeds = folder.feeds.filter { $0.feedID != feed.feedID }
                    
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
