//
//  SearchResultsController.swift
//  elytramac
//
//  Created by Nikhil Nigade on 26/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import AppKit

@objcMembers class SearchResultsController: NSObject {
    
    public var hostedView: NSView?
    
    init(searchResults: [Any]?) {
        
        super.init()
        
        guard let _ = searchResults else {
            hostedView = NSView()
            return
        }
        
        hostedView = NSView()
        
    }
    
}
