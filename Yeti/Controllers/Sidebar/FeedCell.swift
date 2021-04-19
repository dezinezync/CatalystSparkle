//
//  FeedCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 12/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Combine
import Models
import SDWebImage
import DBManager

class FeedCell: UICollectionViewListCell {
    
    weak var feed: Feed!
    var indexPath: IndexPath!
    weak var DS: UICollectionViewDiffableDataSource<Int, SidebarItem>!
    
    var cancellables: [AnyCancellable] = []
    var isExploring: Bool = false
    var isAdding: Bool = false
    
    weak var faviconOp: SDWebImageCombinedOperation?
    
    func configure(item: SidebarItem, indexPath: IndexPath) {
        
        #if targetEnvironment(macCatalyst)
        indentationWidth = 36
        #endif
        
        guard case .feed(let feed) = item else {
            return
        }
        
        self.feed = feed
        self.indexPath = indexPath
        
        var content = isExploring == true ? UIListContentConfiguration.subtitleCell() : UIListContentConfiguration.sidebarCell()
        
        content.imageProperties.accessibilityIgnoresInvertColors = true
        
        content.text = feed.displayTitle
        
        if self.isExploring == true {
            
            content.secondaryText = feed.url.absoluteString
            
        }
        else {
            
            if SharedPrefs.showUnreadCounts == true {
                
                content.secondaryText = feed.unread > 0 ? "\(feed.unread)" : ""
                
                feed.$unread
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] (unread) in
                    
                        guard let sself = self else {
                            return
                        }
                        
                        sself.updateUnreadCount(unread)
                        
                }
                .store(in: &cancellables)
                
            }
            
        }
        
        content.prefersSideBySideTextAndSecondaryText = isExploring == false
        
        if self.isExploring == false {
            
            #if targetEnvironment(macCatalyst)
            content.imageProperties.maximumSize = CGSize(width: 16, height: 16)
            #else
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            #endif
            
            accessories = [UICellAccessory.disclosureIndicator()]
            
        }
        else {
            
            accessories = []
            
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
            
            content.imageProperties.maximumSize = CGSize(width: 32, height: 32)
            
        }
        
        if self.isAdding == true {
            
            content.imageProperties.maximumSize = CGSize.zero
            
        }
        else {
            
            content.imageProperties.cornerRadius = 3
            content.imageProperties.reservedLayoutSize = content.imageProperties.maximumSize
            
            content.image = feed.faviconImage ?? UIImage(systemName: "square.dashed")
            
            feed.$faviconImage
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    
                    guard let sself = self else {
                        return
                    }
                    
                    if (sself.feed.faviconImage == nil) {
                        sself.setupDefaultIcon()
                    }
                    else {
                        
                        guard var content = sself.contentConfiguration as? UIListContentConfiguration else {
                            return
                        }
                        
                        content.image = sself.feed.faviconImage
                        
                        sself.contentConfiguration = content
                        
                    }
                    
                }
                .store(in: &cancellables)
            
            if feed.faviconImage == nil { setupFavicon() }
            
        }
        
        contentConfiguration = content
        
        let shouldIndent = isExploring == false && indexPath.section != SidebarSection.feeds.rawValue
        
        if shouldIndent == true {
            indentationLevel = 1
        }
        else {
            indentationLevel = 0
        }
        
    }
    
    override func prepareForReuse() {
        
        if cancellables.count > 0 {
            
            for c in cancellables {
                c.cancel()
            }
            
            cancellables.removeAll()
            
        }
        
        feed = nil
        
        faviconOp?.cancel()
        
        super.prepareForReuse()
        
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        
        guard var content = contentConfiguration as? UIListContentConfiguration else {
            return
        }
        
        var background = UIBackgroundConfiguration.listSidebarCell().updated(for: state)
        
        if state.isSelected == true {
            content.textProperties.color = .label
            content.secondaryTextProperties.color = tintColor
            background.backgroundColor = .systemFill
        }
        else {
            content.textProperties.color = .label
            content.secondaryTextProperties.color = .secondaryLabel
            background.backgroundColor = .clear
        }
        
        contentConfiguration = content
        backgroundConfiguration = background
        
    }
    
    func updateUnreadCount (_ unread: UInt) {
        
        runOnMainQueueWithoutDeadlocking { [weak self] in
            
            guard var content = self?.contentConfiguration as? UIListContentConfiguration else {
                return
            }
            
            content.secondaryText = unread > 0 ? "\(unread)" : ""
            
            self?.contentConfiguration = content
            
        }
        
    }
    
    func setupDefaultIcon() {
        
        DispatchQueue.main.async { [weak self] in
            
            if self?.feed.faviconImage == nil {
                
                guard var content = self?.contentConfiguration as? UIListContentConfiguration else {
                    return
                }
                
                content.image = UIImage(systemName: "square.dashed")
                
                self?.contentConfiguration = content
                
            }
            
        }
        
    }
    
    func setupFavicon() {
        
        guard let indexPath = indexPath else {
            return
        }
        
        guard case .feed(let feed) = DS.itemIdentifier(for: indexPath) else {
            return
        }
        
        guard feed.faviconImage == nil else {
            return
        }
        
        if faviconOp != nil {
            faviconOp!.cancel()
        }
        
        let maxWidth = 48 * UIScreen.main.scale
        
        guard let url = feed.faviconProxyURI(size: maxWidth) else {
            return
        }
        
        #if DEBUG
//        print("Downloading favicon for feed \(feed.displayTitle) with url \(url)")
        #endif
        
        faviconOp = SDWebImageManager.shared.loadImage(with: url, options: [.scaleDownLargeImages], progress: nil) { [weak self] (image, data, error, cacheType, finished, imageURL) in
            
            guard let sself = self,
                  let sfeed = sself.feed else {
                return
            }
            
            sfeed.faviconImage = image
            
        }
        
    }
    
}
