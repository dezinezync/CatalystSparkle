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

class FeedCell: UICollectionViewListCell {
    
    weak var feed: Feed!
    var indexPath: IndexPath!
    weak var DS: UICollectionViewDiffableDataSource<Int, SidebarItem>!
    
    var cancellables = [AnyCancellable]()
    var isExploring: Bool = false
    var isAdding: Bool = false
    
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
                
                feed.$unread.sink { (unread) in
                    content.secondaryText = (unread ?? 0) > 0 ? "\(unread!)" : ""
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
            
            feed.faviconImage.publisher.sink { [weak self] (image) in
                
                guard let sself = self else {
                    return
                }
                
                guard let cv = sself.superview as? UICollectionView else {
                    return
                }
                
                guard let cell = cv.cellForItem(at: indexPath) else {
                    return
                }
                
                var c = cell.contentConfiguration as! UIListContentConfiguration
                
                if image.size.width > image.size.height {
                    // @TODO: Center the image here and let it overflow horizontally
                }
                
                c.image = image
                
                cell.contentConfiguration = c
                
            }
            .store(in: &cancellables)
            
            setupFavicon()
            
        }
        
        contentConfiguration = content
        
        let shouldIndent = isExploring == false && indexPath.section != 2
        
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
        
        super.prepareForReuse()
        
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        
        var content = contentConfiguration as! UIListContentConfiguration
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
    
    func setupDefaultIcon() {
        
        DispatchQueue.main.async { [weak self] in
            
            if self?.feed.faviconImage == nil {
                self?.feed.faviconImage = UIImage(systemName: "square.dashed")
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
        
        let maxWidth = 48 * UIScreen.main.scale
        
        guard let url = feed.faviconProxyURI(size: maxWidth) else {
            return
        }
        
        let _ = SDWebImageManager.shared.loadImage(with: url, options: [.scaleDownLargeImages], progress: nil) { [weak self] (image, data, error, cacheType, finished, imageURL) in
            
            guard self?.feed != nil || self?.DS != nil || self?.feed.faviconImage == nil || image != nil else {
                self?.setupDefaultIcon()
                return
            }
            
            self?.feed.faviconImage = image
            
        }
        
    }
    
}
