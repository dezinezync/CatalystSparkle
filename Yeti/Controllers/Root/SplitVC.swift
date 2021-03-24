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

@objc class SplitVC: UISplitViewController {
    
    convenience init() {
        
        self.init(style: .tripleColumn)
        
        FeedsManager.shared.user = DBManager.shared.user
        
    }
    
    override func viewDidLoad() {
        
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
            self?.preferredDisplayMode = .twoBesideSecondary
        }
        #else
        minimumPrimaryColumnWidth = 298
        minimumSupplementaryColumnWidth = 375
        setupDisplayModes(size: view.bounds.size)
        #endif
        
        preferredSplitBehavior = .displace
        
        presentsWithGesture = true
        
        self.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        guard let _ = FeedsManager.shared.user else {
            showOnboarding()
            return
        }
        
        #if !DEBUG
        // @TODO: Check and show intro based on hasShownIntro
        showOnboarding()
        #endif
        
    }
    
    // MARK: - Size Changes
    #if !targetEnvironment(macCatalyst)
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        setupDisplayModes(size: size)
        
    }
    
    #endif
    
    // MARK: - Internal
    func setupDisplayModes(size: CGSize) {
        
        if traitCollection.userInterfaceIdiom == .phone {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            
            if size.width < 1024 {
                self?.preferredSplitBehavior = .overlay
            }
            else if size.width > 1024 && size.width < 1180 {
                self?.preferredSplitBehavior = .tile
                self?.preferredDisplayMode = .twoOverSecondary
            }
            else {
                self?.preferredSplitBehavior = .tile
                self?.preferredDisplayMode = .twoBesideSecondary
            }
            
        }
        
    }
    
    func showOnboarding () {
        
        guard presentedViewController == nil else {
            return
        }
        
        NotificationCenter.default.removeObserver(self)
        
        mainCoordinator?.showLaunchVC()
        
    }
    
    // @TODO: Acitivty continuation
    
}

extension SplitVC: UISplitViewControllerDelegate {
    
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        
        if let _ = mainCoordinator?.articleVC {
            return .secondary
        }
        else if let _ = mainCoordinator?.feedVC {
            return .supplementary
        }
        else {
            return .primary
        }
        
    }
    
}

// MARK: - Forwarding
extension SplitVC {
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        
        let str = NSStringFromSelector(aSelector)
        
        if str == "didBeginRefreshing:" || str == "didLongPressOnAllRead:" {
           
            if let f = mainCoordinator?.feedVC {
            
                return f.responds(to: aSelector)  ? f : nil
                
            }
            
            return nil
            
        }
        else if str == "didTapSearch" {
            
            if let a = mainCoordinator?.articleVC {
                
                return a.responds(to: aSelector) ? a : nil
                
            }
            
            return nil
            
        }
        else if str == "showSubscriptionsInterface" {
            
            return mainCoordinator
            
        }
        
        return super.forwardingTarget(for: aSelector)
        
    }

//    override func responds(to aSelector: Selector!) -> Bool {
//        
//        let str = NSStringFromSelector(aSelector)
//        
//        if str == "didBeginRefreshing:" || str == "didLongPressOnAllRead:" {
//           
//            if let f = mainCoordinator?.feedVC as? UIViewController {
//            
//                return f.responds(to: aSelector)
//                
//            }
//            
//            return false
//            
//        }
//        else if str == "didTapSearch" {
//            
//            if let a = mainCoordinator?.articleVC as? UIViewController {
//                
//                return a.responds(to: aSelector)
//                
//            }
//            
//            return false
//            
//        }
//        else if str == "showSubscriptionsInterface" {
//            
//            return true
//            
//        }
//        
//        return super.responds(to: aSelector)
//        
//    }
    
//    override func method(for aSelector: Selector!) -> IMP! {
//
//        let str = NSStringFromSelector(aSelector)
//
//        if str == "didBeginRefreshing:" || str == "didLongPressOnAllRead:" {
//
//            if let f = mainCoordinator?.feedVC as? UIViewController {
//
//                return f.method(for: aSelector)
//
//            }
//
//            return nil
//
//        }
//        else if str == "didTapSearch" {
//
//            if let a = mainCoordinator?.articleVC as? UIViewController {
//
//                return a.method(for: aSelector)
//
//            }
//
//            return nil
//
//        }
//        else if str == "showSubscriptionsInterface" {
//
//            return mainCoordinator?.method(for: aSelector)
//
//        }
//
//        return super.method(for: aSelector)
//
//    }
//
//    func forwardInvocation(_ invocation: NSInvocation) {
//
//
//
//    }
    
}
