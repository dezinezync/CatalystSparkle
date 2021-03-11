//
//  PreviewFolderCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Models

class PreviewFolderCell: UICollectionViewListCell {
    
    weak var folder: Folder!
    
    public func configure(_ folder: Folder) {
        
        self.folder = folder
        
        var content = UIListContentConfiguration.sidebarCell()
        content.text = folder.title
        content.image = UIImage(systemName: "folder")
        
        contentConfiguration = content
        
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        
        if state.isSelected == true {
            
            self.accessories = [.checkmark()]
            
        }
        else {
            self.accessories = []
        }
        
    }
    
}
