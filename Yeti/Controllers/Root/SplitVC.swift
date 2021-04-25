//
//  SplitVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 11/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import UIKit
import Networking
import DBManager
import Defaults

@objcMembers public class SplitVC: UISplitViewController {
    
    var iPadOSShowSidebarInPortraitOnLaunch: Bool = false
    
    convenience init() {
        
        self.init(style: .tripleColumn)
        
        FeedsManager.shared.user = DBManager.shared.user
        
    }
    
    public override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if traitCollection.userInterfaceIdiom == .phone {
            primaryBackgroundStyle = .none
        }
        else {
            primaryBackgroundStyle = .sidebar
        }
        
        maximumPrimaryColumnWidth = 298
        maximumSupplementaryColumnWidth = 375
        
        #if targetEnvironment(macCatalyst)
        preferredPrimaryColumnWidth = 268
        minimumPrimaryColumnWidth = 220
        
        preferredSupplementaryColumnWidth = 320
        minimumSupplementaryColumnWidth = 320
        
        DispatchQueue.main.async { [weak self] in
            self?.preferredSplitBehavior = .tile
            self?.preferredDisplayMode = .oneBesideSecondary
        }
        #else
        minimumPrimaryColumnWidth = 298
        minimumSupplementaryColumnWidth = 375
        #endif
        
        presentsWithGesture = true
        
        self.delegate = self
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        guard let _ = FeedsManager.shared.user else {
            showOnboarding()
            return
        }
        
        #if !DEBUG
        // this prevents skipping the onboarding and trial setup.
        if Defaults[.hasShownIntro] == false {
            showOnboarding()
        }
        #endif
        
    }
    
    // MARK: - Size Changes
    #if !targetEnvironment(macCatalyst)
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        if traitCollection.userInterfaceIdiom == .phone {
            return
        }
        
        coordinator.animate { [weak self] _ in
            self?.setupDisplayModes(size: size)
        } completion: { _ in
            
        }
        
    }
    
    #endif
    
    // MARK: - Internal
    func setupDisplayModes(size: CGSize) {
        
        if traitCollection.userInterfaceIdiom == .phone {
            return
        }
        
        if size.width < 1024 {
            // does not work with any other value
            // for triple column layout.
            
            if (coordinator?.articleVC != nil) {
                preferredDisplayMode = .secondaryOnly
            }
            else {
                preferredDisplayMode = .twoOverSecondary
            }
            
            preferredSplitBehavior = .overlay
            
        }
        else if size.width > 1024 && size.width < 1180 {
            
            if (coordinator?.articleVC != nil) {
                preferredDisplayMode = .oneBesideSecondary
            }
            else {
                preferredDisplayMode = .twoOverSecondary
            }
            
            preferredSplitBehavior = .tile
        }
        else {
            
            if (coordinator?.articleVC != nil) {
                preferredDisplayMode = .oneBesideSecondary
            }
            else {
                preferredDisplayMode = .twoBesideSecondary
            }
            
            preferredSplitBehavior = .tile
        }
        
    }
    
    func showOnboarding () {
        
        NotificationCenter.default.removeObserver(self)
        
        coordinator?.showLaunchVC()
        
    }
    
    // @TODO: Acitivty continuation
    
}

extension SplitVC: UISplitViewControllerDelegate {
    
    public func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        
        print(displayMode.rawValue)
        
        if displayMode == .secondaryOnly,
           iPadOSShowSidebarInPortraitOnLaunch == false {
            
            DispatchQueue.main.async { [weak self] in
                self?.setupDisplayModes(size: svc.view.bounds.size)
                
                self?.iPadOSShowSidebarInPortraitOnLaunch = true
            }
            
        }
        
    }
    
    public func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.swap(svc, collapsing: true)
        }
        
        return proposedTopColumn
        
//        if let _ = coordinator?.articleVC {
//            return .secondary
//        }
//        else if let _ = coordinator?.feedVC {
//            return .supplementary
//        }
//        else {
//            return .primary
//        }
        
    }
    
    public func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.swap(svc, collapsing: false)
        }
        
        // this will still crash UISplitViewController's internal implementation.
        if coordinator?.feedVC == nil,
           proposedDisplayMode == .twoOverSecondary {
            
           return .oneOverSecondary
            
        }
        
        return proposedDisplayMode
        
    }
    
    /// https://www.biteinteractive.com/split-view-controllers-done-right-in-ios-14/
    func swap(_ svc: UISplitViewController, collapsing: Bool) {
        if collapsing {
            
            if let nav = svc.viewController(for: .compact) as? UINavigationController {
                
                // pop each controller and push it on to the compact stack
                if let feedVC = coordinator?.feedVC {
                    
                    if let fnav = feedVC.navigationController {
                        
                        if let vc = fnav.popViewController(animated: false) {
                            
                            nav.pushViewController(vc, animated: false)
                            
                        }
                        else {
                            
                            nav.pushViewController(coordinator!.feedVC!, animated: false)
                            
                        }
                                                
                    }
                    
                }
                
                if let articleVC = coordinator?.articleVC {
                    
                    if let anav = articleVC.navigationController {
                        
                        if let vc = anav.popViewController(animated: false) {
                            
                            nav.pushViewController(vc, animated: false)
                            
                        }
                        else {
                            
                            nav.pushViewController(coordinator!.articleVC!, animated: false)
                            
                        }
                                                
                    }
                    
                }
                
            }
            
        }
        else {
                
            if let nav = svc.viewController(for: .compact) as? UINavigationController {
                
                let articleVC: ArticleVC? = coordinator?.articleVC != nil ? nav.popViewController(animated: true) as? ArticleVC : nil
                let feedVC: FeedVC? = coordinator?.feedVC != nil ? nav.popViewController(animated: false) as? FeedVC : nil
                
                if let fvc = feedVC {
                    svc.setViewController(UINavigationController(rootViewController: fvc), for: .supplementary)
                }
                
                if let avc = articleVC {
                    svc.setViewController(UINavigationController(rootViewController: avc), for: .secondary)
                }
                
            }
            
        }
        
    }
    
}

// MARK: - Forwarding
extension SplitVC {
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        
        let str = NSStringFromSelector(aSelector)
        
        if str == "beginRefreshingAll:" || str == "didTapMarkAll:" {
           
            if let f = coordinator?.feedVC {
            
                return f.responds(to: aSelector)  ? f : nil
                
            }
            
            return nil
            
        }
        else if str == "didTapSearch" {
            
            if let a = coordinator?.articleVC {
                
                return a.responds(to: aSelector) ? a : nil
                
            }
            
            return nil
            
        }
        else if str == "showSubscriptionsInterface" {
            
            return coordinator
            
        }
        
        return super.forwardingTarget(for: aSelector)
        
    }

    public override func responds(to aSelector: Selector!) -> Bool {
        
        let str = NSStringFromSelector(aSelector)
//        print(str)
        if str == "beginRefreshingAll:" || str == "didTapMarkAll:" {
           
            if let f = coordinator?.feedVC {
            
                return f.responds(to: aSelector)
                
            }
            
            return false
            
        }
        else if str == "didTapSearch" {
            
            if let a = coordinator?.articleVC {
                
                return a.responds(to: aSelector)
                
            }
            
            return false
            
        }
        else if str == "showSubscriptionsInterface" {
            
            return true
            
        }
        
        return super.responds(to: aSelector)
        
    }
    
    override public func method(for aSelector: Selector!) -> IMP! {

        let str = NSStringFromSelector(aSelector)

        if str == "beginRefreshingAll:" || str == "didTapMarkAll:" {

            if let f = coordinator?.feedVC {

                return f.method(for: aSelector)

            }

            return nil

        }
        else if str == "didTapSearch" {

            if let a = coordinator?.articleVC {

                return a.method(for: aSelector)

            }

            return nil

        }
        else if str == "showSubscriptionsInterface" {

            return coordinator?.method(for: aSelector)

        }

        return super.method(for: aSelector)

    }
    
}
