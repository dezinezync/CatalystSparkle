//
//  SceneDelegate.swift
//  Elytra
//
//  Created by Nikhil Nigade on 24/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import BackgroundTasks
import CoreSpotlight
import JLRoutes
import Defaults
import Dynamic
import Models

let backgroundCleanupIdentifier: String = "com.yeti.cleanup"
let backgroundRefreshIdentifier: String = "com.yeti.refresh"

let viewImageActivity = "viewImage"
let openArticleActivity = "openArticle"
let subscriptionsActivity = "subscriptionsInterface"
let attributionsActivity = "attributionsScene"
let newFeedActivity = "newFeedScene"
let opmlImportActivity = "opmlScene:0"
let opmlExportActivity = "opmlScene:1"

let DEFAULT_ACTIVITIES: Set<String> = Set(["main"])

@objcMembers class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    #if targetEnvironment(macCatalyst)
    
    weak var toolbar: NSToolbar?
    
    weak var sortingItem: SortingMenuToolbarItem?
    
    var toolbarDelegate: SceneToolbarDelegate?
    
    #endif
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene: UIWindowScene = scene as? UIWindowScene else {
            return
        }
        
        #if targetEnvironment(macCatalyst)
        
        if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity,
           DEFAULT_ACTIVITIES.contains(activity.activityType) == false {
            
            handleActivity(activity, scene: windowScene)
            return
            
        }
        
        guard MyAppDelegate.mainScene == nil else {
            
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil, errorHandler: nil)
            
            return
            
        }
        #endif
        
        setupBackgroundCleanup()
        
        #if !targetEnvironment(macCatalyst)
        setupBackgroundRefresh()
        #endif
        
        window = UIWindow(windowScene: windowScene)
        window!.tintColor = SharedPrefs.tintColor
        
        let splitVC = SplitVC()
        window!.rootViewController = splitVC
        
        MyAppDelegate.coordinator.start(splitVC)
        
        splitVC.loadViewIfNeeded()
        
        MyAppDelegate.mainScene = windowScene
        
        #if targetEnvironment(macCatalyst)
        ct_setupToolbar(scene: windowScene)
        
        windowScene.titlebar?.titleVisibility = .visible
        windowScene.titlebar?.toolbarStyle = .unifiedCompact
        #endif
        
        window!.makeKeyAndVisible()
        
        if connectionOptions.urlContexts.count > 0 {
            
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
            
        }
        
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    
        WidgetManager.updateState()
        
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        
        _checkForAppResetPref()
        
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        
        guard scene == MyAppDelegate.mainScene else {
            return
        }
        
        WidgetManager.reloadAllTimelines()
        
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            
            var cancelling: Bool = true
            
            if requests.count == 0 {
                cancelling = false
            }
            
            #if !targetEnvironment(macCatalyst)
            self.scheduleBackgroundRefresh()
            #endif
            self.scheduleBackgroundCleanup()
            
            #if DEBUG
            if cancelling == true {
                
                MyAppDelegate.bgTaskDispatchQueue.async {
                    BGTaskScheduler.shared.perform(NSSelectorFromString("_simulateLaunchForTaskWithIdentifier:"), with: backgroundRefreshIdentifier)
                }
                
            }
            #endif
            
        }
        
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        
        guard userActivity.activityType == CSSearchableItemActionType else {
            return
        }
        
        guard let uniqueIdentifer: String = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        
        if uniqueIdentifer.contains("feed:") == true {
            
            let feedID: String = uniqueIdentifer.replacingOccurrences(of: "feed:", with: "")
            
            if let url = URL(string: "elytra://feed/\(feedID)") {
                runOnMainQueueWithoutDeadlocking {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
        }
        
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        guard URLContexts.count > 0 else {
            return
        }
        
        let context: UIOpenURLContext = URLContexts.first!
        
        let url = context.url
        
        let _ = JLRoutes.routeURL(url)
        
    }
    
    // MARK: - Activity Handlers
    
    func _checkForAppResetPref() {
        
        guard Defaults[.resetAccount] == true else {
            return
        }
        
        MyAppDelegate.coordinator.resetAccount {
            
            MyAppDelegate.coordinator.showLaunchVC()
            
            Defaults[.resetAccount] = false
            
        }
        
    }
    
    func handleActivity(_ activity: NSUserActivity, scene: UIWindowScene) {
        
        var window: UIWindow?
        
        #if targetEnvironment(macCatalyst)
        
        if activity.activityType == viewImageActivity {
            
            window = UIWindow(windowScene: scene)
            window!.canResizeToFitContent = true
            
            let vc = PhotosController(userInfo: activity.userInfo ?? [:])
            vc.coordinator = MyAppDelegate.coordinator
            window!.rootViewController = vc
            
            if let sizeString: String = activity.userInfo?["size"] as? String {
                
                let size = NSCoder.cgSize(for: sizeString)
                scene.sizeRestrictions?.minimumSize = size
                
            }
            
            scene.titlebar?.titleVisibility = .hidden
            scene.titlebar?.toolbar = nil
                                   
        }
        else if activity.activityType == openArticleActivity {
            
            window = UIWindow(windowScene: scene)
            scene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 480)
            // @TODO: Add a toolbar here.
            scene.titlebar?.toolbar = nil
            
            if let dict = activity.userInfo as? [String: AnyHashable] {
                
                let item: Article = Article(from: dict)
                let vc = ArticleVC(item: item)
                vc.coordinator = MyAppDelegate.coordinator
                vc.isExternalWindow = true
                
                let feed = MyAppDelegate.coordinator.feedFor(item.feedID)
                
                if let title = item.title, let displayTitle = feed?.displayTitle {
                    scene.title = "\(title) - \(displayTitle)"
                }
                
                window!.rootViewController = vc
                
            }
            
        }
        else if activity.activityType == subscriptionsActivity {
            
            window = UIWindow(windowScene: scene)
            window?.canResizeToFitContent = false
            
            let fixedSize = CGSize(width: 375, height: 480)
            scene.sizeRestrictions?.maximumSize = fixedSize
            scene.sizeRestrictions?.minimumSize = fixedSize
            
            scene.title = "Your Subscription"
            
            let vc = StoreVC(style: .grouped)
            vc.coordinator = MyAppDelegate.coordinator
            
            window!.rootViewController = vc
            
        }
        else if activity.activityType == attributionsActivity {
            
            window = UIWindow(windowScene: scene)
            window?.canResizeToFitContent = false
            
            let fixedSize = CGSize(width: 375, height: 480)
            scene.sizeRestrictions?.minimumSize = fixedSize
            
            scene.title = "Attributions"
            
            let vc = DZWebViewController()
            vc.title = "Attributions"
            vc.coordinator = MyAppDelegate.coordinator
            
            vc.url = Bundle(for: Self.self).url(forResource: "attributions", withExtension: "html")
            
            let tint = UIColor.hex(from: SharedPrefs.tintColor)
            let js = "anchorStyle(\(tint!))"
            
            vc.evalJSOnLoad = js
            
            window!.rootViewController = vc
            
        }
        else if activity.activityType == newFeedActivity {
            
            window = UIWindow(windowScene: scene)
            window?.canResizeToFitContent = false
            
            let fixedSize = CGSize(width: 375, height: 480)
            scene.sizeRestrictions?.minimumSize = fixedSize
            scene.sizeRestrictions?.maximumSize = fixedSize
            
            scene.titlebar?.titleVisibility = .visible
            scene.titlebar?.toolbarStyle = .unified
            scene.title = "New Feed"
            
            let vc = NewFeedVC(collectionViewLayout: NewFeedVC.gridLayout)
            vc.coordinator = MyAppDelegate.coordinator
            
            window!.rootViewController = vc
            
        }
        else if activity.activityType.contains("opmlScene") {
            
            window = UIWindow(windowScene: scene)
            window?.canResizeToFitContent = false
            
            scene.sizeRestrictions?.minimumSize = CGSize(width: 375, height: 480)
            scene.sizeRestrictions?.maximumSize = CGSize(width: 480, height: 600)
            
            let typeString = activity.activityType.replacingOccurrences(of: "opmlScene:", with: "")
            let type = ShowOPMLType(rawValue: (typeString as NSString).integerValue)!
            
            let vc = OPMLVC(nibName: "OPMLVC", bundle: Bundle.main)
            vc.coordinator = MyAppDelegate.coordinator
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true
            
            window!.rootViewController = nav
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                
                vc.loadViewIfNeeded()
                
                self._disableFullScreenOnWindow(window!)
                            
                if type == .Export {
                    vc.didTapExport(nil)
                }
                else if type == .Import {
                    vc.didTapImport(nil)
                }
                
            }
            
        }
        
        #endif
        
        if (window != nil && window!.rootViewController != nil) {
            
            self.window = window
            window!.tintColor = SharedPrefs.tintColor
            
            window!.makeKeyAndVisible()
            
        }
        else {
            window = nil
        }
        
    }
    
    func _disableFullScreenOnWindow(_ window: UIWindow) {
        
        #if targetEnvironment(macCatalyst)
        
        guard let nsWindow = window.nsWindow else {
            return
        }
        
        MyAppDelegate.sharedGlue.disableFullscreenButton(nsWindow)
        
        #endif
        
    }
    
    // MARK: - Background Activities
    
    func setupBackgroundCleanup() {
        
        guard MyAppDelegate.bgCleanupTaskHandlerRegistered == false else {
            return
        }
        
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundCleanupIdentifier, using: nil) { [weak self] task in
            
            guard let sself = self,
                  let task = task as? BGProcessingTask else { return }
            
            print("Woken to perform background cleanup.")
            
            sself.scheduleBackgroundCleanup()
            
            MyAppDelegate.coordinator.setupBGCleanup(task: task)
            
        }
        
        MyAppDelegate.bgCleanupTaskHandlerRegistered = registered
        
        print("Registered background cleanup task: \(registered ? "Yes": "No")")
        
    }
    
    func setupBackgroundRefresh() {
        
        guard MyAppDelegate.bgTaskHandlerRegistered == false else {
            return
        }
        
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundCleanupIdentifier, using: nil) { [weak self] task in
            
            guard let sself = self,
                  let task = task as? BGAppRefreshTask else { return }
            
            print("Woken to perform background sync.")
            
            sself.scheduleBackgroundRefresh()
            
            guard let _ = MyAppDelegate.coordinator.user else {
                return
            }
            
            MyAppDelegate.coordinator.setupBGSyncCoordinator(task: task) { completed in
                
                MyAppDelegate.coordinator.completedBGSync()
                
                guard completed == true else {
                    return
                }
                
                guard let sidebarVC = MyAppDelegate.coordinator.sidebarVC else {
                    return
                }
                
                runOnMainQueueWithoutDeadlocking {
                    
                    sidebarVC.updateLastUpdatedText()
                    
                    WidgetManager.reloadAllTimelines()
                    
                }
                
            }
            
        }
        
        MyAppDelegate.bgTaskHandlerRegistered = registered
        
        print("Registered background sync task: \(registered ? "Yes": "No")")
        
    }
    
    func scheduleBackgroundRefresh() {
        
        // Note from NetNewsWire code
        // We send this to a dedicated serial queue because as of 11/05/19 on iOS 13.2 the call to the
        // task scheduler can hang indefinitely.
        
        MyAppDelegate.bgTaskDispatchQueue.async {
            
            let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
            
            // Can be done 60min from now.
            #if DEBUG
            request.earliestBeginDate = Date().addingTimeInterval(1)
            #else
            request.earliestBeginDate = Date().addingTimeInterval(60 * 60)
            #endif
            
            do {
                try BGTaskScheduler.shared.submit(request)
            }
            catch {
                
                let error = error as NSError
                if error.code != 1 {
                    print("Error submitting bg cleanup request: \(error.localizedDescription)")
                }
                
            }
            
        }
        
    }
    
    func scheduleBackgroundCleanup() {
        
        // Note from NetNewsWire code
        // We send this to a dedicated serial queue because as of 11/05/19 on iOS 13.2 the call to the
        // task scheduler can hang indefinitely.
        
        MyAppDelegate.bgTaskDispatchQueue.async {
            
            let request = BGProcessingTaskRequest(identifier: backgroundCleanupIdentifier)
            request.requiresExternalPower = false
            request.requiresNetworkConnectivity = false
            
            // Can be done 5min from now.
            #if DEBUG
            request.earliestBeginDate = Date().addingTimeInterval(1)
            #else
            request.earliestBeginDate = Date().addingTimeInterval(60 * 5)
            #endif
            
            do {
                try BGTaskScheduler.shared.submit(request)
            }
            catch {
                
                let error = error as NSError
                if error.code != 1 {
                    print("Error submitting bg cleanup request: \(error.localizedDescription)")
                }
                
            }
            
        }
        
    }
    
}

// MARK: - Toolbar Support
extension SceneDelegate {
    
    func ct_setupToolbar(scene: UIWindowScene) {
        
        #if targetEnvironment(macCatalyst)
        
        if scene == MyAppDelegate.mainScene {
            
            let toolbar = NSToolbar(identifier: "elytra-main-toolbar")
            toolbar.displayMode = .iconOnly
            toolbarDelegate = SceneToolbarDelegate(scene: scene)
            
            toolbar.delegate = toolbarDelegate
            
            scene.titlebar?.toolbar = toolbar
            
            self.toolbar = toolbar
            
        }
        
        #endif
        
    }
    
}
