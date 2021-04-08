//
//  FolderVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 22/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Models
import Combine
import DBManager
import SwiftYapDatabase
import YapDatabase
import Dynamic

class FolderVC: FeedVC {
    
    @objc var folder: Folder!

    override func viewDidLoad() {
        
        type = .folder
        
        super.viewDidLoad()
        
    }
    
    // MARK: - Setup
    
    override func setupFeed() {
        
        super.setupFeed()
        
        // case doesn't have implementation for folder.
        
        self.title = folder.title
        
        self.titleView?.faviconView.isHidden = true
        
        folder.title.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (title) in
                
                self?.title = title
                self?.titleView?.titleLabel.text = title
                
            }
            .store(in: &cancellables)
        
        folder.$unread
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (unread) in
                
                guard let sself = self else {
                    return
                }
                
                sself.titleView?.countLabel.text = "\(unread) Unread\(unread == 1 ? "" : "s")"
                
            }
            .store(in: &cancellables)
        
    }
    
    #if targetEnvironment(macCatalyst)
    public override func setupTitleView() {
        
        guard let title: String = self.title else {
            return
        }
        
        guard let window = coordinator?.innerWindow else {
            return
        }
        
        super.setupTitleView()
        
        Dynamic(window).title = title
        
        folder.$unread
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
    #endif
    
    override var dbAutoViewName: String {
        
        let sortingKey: Int = self.sorting.isAscending == true ? 1 : 2;
        
        let feedKey: String = "folder:\(folder!.folderID!)"
        
        return "feedFilteredView::\(feedKey)::\(sortingKey)"
        
    }
    
    override func setupViews() {
        
        let baseViewName = sorting.isUnread == true ? DBManagerViews.unreadsView : DBManagerViews.articlesView
        
        let filtering = YapDatabaseViewFiltering.withMetadataBlock { [weak self] (t, g, c, k, m) -> Bool in
            
            guard let sself = self,
                  let metadata = m as? ArticleMeta else {
                return false
            }
            
            if sself.folder.feedIDs.contains(metadata.feedID) == false {
                return false
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
            
            let filteredView = YapDatabaseFilteredView(parentViewName: baseViewName.rawValue, filtering: filtering, versionTag: "\(FeedVC.filteringTag)")
            
            DBManager.shared.database.register(filteredView, withName: dbFilteredViewName)
            
            self?.dbFilteredView = filteredView
            
        }
        
        DBManager.shared.writeQueue.async { [weak self] in
            
            self?.loadNextPage()
            
        }
        
    }

    // MARK: - State
    override var emptyViewDisplayTitle: String {
        return folder.title
    }

}
