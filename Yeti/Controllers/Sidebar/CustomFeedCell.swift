//
//  CustomFeedCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 13/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Combine
import Models
import SDWebImage

class CustomFeedCell: UICollectionViewListCell {
    
    weak var feed: CustomFeed!
    weak var coordinator: MainCoordinator?
    var cancellables = [AnyCancellable]()
    
    func configure(item: SidebarItem, indexPath: IndexPath) {
        
        #if targetEnvironment(macCatalyst)
        indentationWidth = 36
        #endif
        
        guard case .custom(let feed) = item else {
            return
        }
        
        self.feed = feed
        
        var content = UIListContentConfiguration.sidebarCell()
        
        content.text = feed.title
        
        if SharedPrefs.showUnreadCounts == true {
            
            switch feed.feedType {
            case .unread:
                coordinator?.publisher(for: \.totalUnread)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] (unread) in
                        self?.updateUnreadCount(unread)
                    })
                    .store(in: &cancellables)
                
            case .today:
                coordinator?.publisher(for: \.totalToday)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] (unread) in
                        self?.updateUnreadCount(unread)
                    })
                    .store(in: &cancellables)
            default:
                break
            }
            
        }
        
        content.prefersSideBySideTextAndSecondaryText = true
        
        #if targetEnvironment(macCatalyst)
        content.imageProperties.maximumSize = CGSize(width: 16, height: 16)
        #else
        content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        #endif
        
        content.imageProperties.tintColor = feed.color
        content.imageProperties.cornerRadius = 3
        content.imageProperties.reservedLayoutSize = content.imageProperties.maximumSize
        
        content.image = feed.image
        
        contentConfiguration = content
        
        accessories = [UICellAccessory.disclosureIndicator()]
        
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
        
        guard var content = contentConfiguration as? UIListContentConfiguration else {
            return
        }
        
        content.secondaryText = unread > 0 ? "\(unread)" : ""
        
        contentConfiguration = content
        
    }
    
}
