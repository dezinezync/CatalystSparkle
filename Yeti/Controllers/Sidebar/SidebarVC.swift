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

@objc class CustomFeed: NSObject {
    
    let title: String
    let image: UIImage?
    
    required init(title: String, image: String) {
        self.title = title
        self.image = UIImage(systemName: image)
    }
    
}

fileprivate enum Section: CaseIterable {
    
    case custom
    case folders
    case feeds
    
}

fileprivate enum Item: Hashable {
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        
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
}

@objc class SidebarVC: UICollectionViewController {
    
    lazy var layout: UICollectionViewCompositionalLayout = {
       
        var l = UICollectionViewCompositionalLayout { (section, environment) -> NSCollectionLayoutSection? in
            
            let appearance: UICollectionLayoutListConfiguration.Appearance = environment.traitCollection.userInterfaceIdiom == .phone ? .plain : .sidebar
            
            var config = UICollectionLayoutListConfiguration(appearance: appearance)
            config.showsSeparators = false
            
            if section == 0 {
                #if targetEnvironment(macCatalyst)
                config.headerMode = .supplementary
                #endif
                
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            }
            
            if section == 2 {
                // this is only applicable for feeds with folders
                config.headerMode = .firstItemInSection
            }
            
            config.trailingSwipeActionsConfigurationProvider = { [weak self] (indexPath) -> UISwipeActionsConfiguration? in
                
                guard let sself = self else { return nil }
                
                guard let item = sself.DS.itemIdentifier(for: indexPath) else { return nil }
                
                var swipeConfig: UISwipeActionsConfiguration? = nil
                
                if case Item.feed(let feed) = item {
                    
                    let delete = UIContextualAction(style: .destructive, title: "Delete") { (a, sourceView, completionHandler) in
                        
                        
                        
                    }
                    
                    let move = UIContextualAction(style: .normal, title: "Move") { (a, sourceView, completionHandler) in
                        
                        
                        
                    }
                    
                    move.backgroundColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
                    
                    let share = UIContextualAction(style: .normal, title: "Share") { (a, sourceView, completionHandler) in
                        
                        
                        
                    }
                    
                    share.backgroundColor = UIColor(red: 126/255, green: 211/255, blue: 33/255, alpha: 1)
                    
                    swipeConfig = UISwipeActionsConfiguration(actions: [delete, move, share])
                    
                }
                
                swipeConfig?.performsFirstActionWithFullSwipe = true
                
                return swipeConfig
                
            }
            
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            
        }
        
        return l
        
    }()
    
    fileprivate lazy var DS: UICollectionViewDiffableDataSource<Int, Item> = {
        
        let ds = UICollectionViewDiffableDataSource<Int, Item>(collectionView: collectionView) { (cv, indexPath, item: Item) -> UICollectionViewCell? in
            
            if case .feed(let feed) = item {
                
            }
            
            return nil
            
        }
        
        return ds
        
    }()
    
    @objc convenience init() {

        self.init()
        collectionView.setCollectionViewLayout(layout, animated: false)

    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "Feeds"
        
        if traitCollection.userInterfaceIdiom == .phone {
            collectionView.backgroundColor = .systemBackground
        }
        
        #if targetEnvironment(macCatalyst)
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
        
        scheduleTimerIfValid()
        
        #endif
        
        setupNavigationBar()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
//        #if !targetEnvironment(macCatalyst)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        
        if SharedPrefs.useToolbar == true {
            
//            if DBManager.shared.sync
            
        }
        
//        #endif
        
    }
    
    // MARK: - Setups
    func setupNavigationBar() {
        
        
        
    }
    
    @objc func setupData() {
        
    }
    
    // MARK: - Actions
    @objc func beginRefreshingAll(_ sender: Any?) {
        
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
        
        guard SharedPrefs.refreshFeedsInterval != "-1" else {
            return
        }
        
        let interval = (SharedPrefs.refreshFeedsInterval as NSString).doubleValue
        
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
