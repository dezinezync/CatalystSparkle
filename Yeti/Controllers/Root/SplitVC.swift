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
    
    public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        guard let _ = FeedsManager.shared.user else {
            showOnboarding()
            return
        }
        
//        #if !DEBUG
        // this prevents skipping the onboarding and trial setup.
        if Defaults[.hasShownIntro] == false {
            showOnboarding()
        }
//        #endif
        
    }
    
    // MARK: - Size Changes
    #if !targetEnvironment(macCatalyst)
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
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
        
        NotificationCenter.default.removeObserver(self)
        
        coordinator?.showLaunchVC()
        
    }
    
    // @TODO: Acitivty continuation
    
}

extension SplitVC: UISplitViewControllerDelegate {
    
    public func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        
        if let _ = coordinator?.articleVC {
            return .secondary
        }
        else if let _ = coordinator?.feedVC {
            return .supplementary
        }
        else {
            return .primary
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
