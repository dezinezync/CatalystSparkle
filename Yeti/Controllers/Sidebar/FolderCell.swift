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
    
    var cancellables: [AnyCancellable] = []
    
    func configure(_ item: SidebarItem, indexPath: IndexPath) {
        
        guard case .folder(let folder) = item else {
            return
        }
        
        self.folder = folder
        self.item = item
        self.indexPath = indexPath
        
        var content = UIListContentConfiguration.sidebarHeader()
        
        content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
        
        folder.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (title) in
            
            guard let sself = self else {
                return
            }
            
            CoalescingQueue.standard.add(sself, #selector(sself.updateTitle))
            
        }
        .store(in: &cancellables)
        
        if SharedPrefs.showUnreadCounts == true {
            
            folder.$unread
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (unread) in
                    
                    guard let sself = self else {
                        return
                    }
                
                    CoalescingQueue.standard.add(sself, #selector(sself.updateUnreadCount))
                
            }
            .store(in: &cancellables)
            
        }
        
        content.textProperties.color = .label
        
        content.secondaryTextProperties.color = .secondaryLabel
        
        content.prefersSideBySideTextAndSecondaryText = true
        
        let expanded = DS?.snapshot(for: SidebarSection.folders.rawValue).isExpanded(item)
        
        let imageName = expanded == true ? "folder" : "folder.fill"
        
        content.image = UIImage(systemName: imageName)
        
        content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        
        contentConfiguration = content
        
        if accessories.count == 0 {
            
            let options = UICellAccessory.OutlineDisclosureOptions(style: .cell)
            let disclosure = UICellAccessory.outlineDisclosure(options: options)
            
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
    
    @objc func updateUnreadCount () {
        
        guard var content = contentConfiguration as? UIListContentConfiguration else {
            return
        }
        
        let unread = self.folder?.unread ?? 0
        
        content.secondaryText = unread > 0 ? "\(unread)" : ""
        
        contentConfiguration = content
        
    }
    
    @objc func updateTitle() {
        
        guard var content = contentConfiguration as? UIListContentConfiguration else {
            return
        }
        
        content.text = folder!.title
        
        runOnMainQueueWithoutDeadlocking { [weak self] in
            self?.contentConfiguration = content
        }
        
    }
    
}
