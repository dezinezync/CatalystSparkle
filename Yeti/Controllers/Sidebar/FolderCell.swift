//
//  FolderCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 14/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Models
import Combine

class FolderCell: UICollectionViewListCell {
    
    weak var folder: Folder?
    var item: SidebarItem?
    var indexPath: IndexPath?
    weak var DS: UICollectionViewDiffableDataSource<Int, SidebarItem>?
    
    var cancellables = [AnyCancellable]()
    
    func configure(_ item: SidebarItem, indexPath: IndexPath) {
        
        guard case .folder(let folder) = item else {
            return
        }
        
        self.folder = folder
        self.item = item
        self.indexPath = indexPath
        
        var content = UIListContentConfiguration.sidebarHeader()
        
        content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
        
        content.text = folder.title
        
        folder.title.publisher.sink { [weak self] (title) in
            
            guard let sself = self else {
                return
            }
            
            guard var c = sself.contentConfiguration as? UIListContentConfiguration else {
                return
            }
            
            c.text = title
            sself.contentConfiguration = c
            
        }
        .store(in: &cancellables)
        
        if SharedPrefs.showUnreadCounts == true {
            
//            folder.publisher(for: \.unread).sink { [weak self] (unread) in
//                
//                guard let sself = self else {
//                    return
//                }
//                
//                guard var c = sself.contentConfiguration as? UIListContentConfiguration else {
//                    return
//                }
//                
//                c.secondaryText = "\(unread)"
//                
//                sself.contentConfiguration = c
//                
//            }
//            .store(in: &cancellables)
            
        }
        
        if traitCollection.userInterfaceIdiom == .mac {
            content.textProperties.color = .secondaryLabel
        }
        else {
            content.textProperties.color = .label
        }
        
        content.secondaryTextProperties.color = .secondaryLabel
        
        content.prefersSideBySideTextAndSecondaryText = true
        
        let expanded = DS?.snapshot(for: SidebarSection.folders.rawValue).isExpanded(item)
        
        let imageName = expanded == true ? "folder" : "folder.fill"
        
        content.image = UIImage(systemName: imageName)
        
        content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        
        contentConfiguration = content
        
        if accessories.count == 0 {
            
            let disclosure = UICellAccessory.outlineDisclosure()
            
            accessories = [disclosure]
            
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
        
        guard var updatedContent = self.contentConfiguration as? UIListContentConfiguration,
              var background = self.backgroundConfiguration else {
            return
        }
        
        if traitCollection.userInterfaceIdiom == .phone {
            
            background.backgroundColor = .systemBackground
            
        }
        
        if state.isExpanded == true {
            
            updatedContent.image = UIImage(systemName: "folder")
            
        }
        else {
            
            updatedContent.image = UIImage(systemName: "folder.fill")
            
        }
        
        if state.isSelected == true {
            
            background.backgroundColor = .tertiarySystemFill
            
        }
        else {
            background.backgroundColor = .clear
        }
        
        backgroundConfiguration = background
        contentConfiguration = updatedContent
        
    }
    
}
