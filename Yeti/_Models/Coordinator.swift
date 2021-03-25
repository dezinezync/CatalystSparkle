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
    
    var totalUnread: UInt = 0
    var totalToday: UInt = 0
    var totalBookmarks: UInt = 0
    
    weak public var splitVC: SplitVC?
    weak public var sidebarVC: SidebarVC?
    weak public var feedVC: FeedVC?
    weak public var articleVC: ArticleVC?
    weak public var emptyVC: EmptyVC?
    
    public func start(_ splitViewController: SplitVC) {
        
        self.splitVC = splitViewController
        
        let sidebar = SidebarVC()
        sidebar.coordinator = self
        
        let nav = UINavigationController(rootViewController: sidebar)
        sidebar.navigationController?.navigationBar.prefersLargeTitles = true
        sidebar.navigationItem.largeTitleDisplayMode = .automatic
        
        splitVC?.setViewController(nav, for: .primary)
        
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
                // @TODO
            }
            
            if showEmpty {
                self?.showEmptyVC()
            }
            
            sself.checkForPushNotifications()
            
        }
        
    }
    
    // MARK: - Feeds
    public func showCustomVC(_ feed: CustomFeed) {
        
        if feed.feedType == .unread && (self.feedVC != nil && self.feedVC!.type != .unread) {
            
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
    
    // MARK: - Articles
    public func showArticleVC(_ articleVC: ArticleVC) {
        
        articleVC.coordinator = self
        
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
        
        // @TODO
        
    }
    
    public func showNewFeedVC() {
        
        #if targetEnvironment(macCatalyst)
        // @TODO
        #else
        
        let vc = NewFeedVC(collectionViewLayout: NewFeedVC.gridLayout)
        vc.coordinator = self
        vc.moveFoldersDelegate = sidebarVC
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        splitVC?.present(nav, animated: true, completion: nil)
        
        #endif
        
    }
    
    var newFolderController: NewFolderController?
    
    public func showNewFolderVC() {
        
        // @TODO
        
    }
    
    public func showRenameFolderVC() {
        
        // @TODO
        
    }
    
    public func showSettingsVC () {
        
        // @TODO
        
    }
    
    public func showOPMLInterface(from sender: Any, type: ShowOPMLType) {
        
        // @TODO
        
    }
    
    public func showContactInterface() {
        
        
        
    }
    
    public func showFeedInfo (feed: Feed, from: UIViewController) {
        
        let vc = FeedInfoController(feed: feed)
        vc.coordinator = self
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        from.present(nav, animated: true, completion: nil)
        
    }
    
    #if targetEnvironment(macCatalyst)
    
    public func showAttributions() {
        
        // @TODO
        
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
            
            var nsWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.innerWindow()
            
            if nsWindow == nil {
                
                // try again in 1s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    
                    nsWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.innerWindow()
                    
                    if nsWindow != nil {
                        
                        self?.innerWindow = nsWindow
                        
                        if self?.feedVC != nil {
                            self?.feedVC?.updateTitleView()
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

    var registerNotificationsTimer :Timer?
    
    public func registerForNotifications(completion: ((_ error: Error?, _ completed: Bool) -> Void)?) {
        
        // @TODO
        
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
