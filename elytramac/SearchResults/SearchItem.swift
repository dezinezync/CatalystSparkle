//
//  SearchItem.swift
//  elytramac
//
//  Created by Nikhil Nigade on 27/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Cocoa

@objcMembers public class SearchItem: NSObject {
    
    dynamic let identifier: String
    
    dynamic let imagePath: URL?
    
    dynamic let label: String
    
    dynamic let detailLabel: String?
    
    init(identifier: String, imagePath: URL?, label: String, detailLabel: String?) {
        
        self.identifier = identifier
        self.imagePath = imagePath
        self.label = label
        self.detailLabel = detailLabel
        
    }
    
    dynamic var image: NSImage?
    
}
