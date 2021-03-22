//
//  UnreadVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 22/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Defaults
import DBManager
import YapDatabase
import SwiftYapDatabase

class UnreadVC: FeedVC {
    
    var originalSortOption: FeedSorting!

    override func viewDidLoad() {
        
        self.type = .unread
        
        originalSortOption = FeedSorting(rawValue: Defaults[.feedSorting])
        var option = FeedSorting(rawValue: originalSortOption.rawValue)!
        
        if originalSortOption == .descending {
            option = .unreadDescending
        }
        else if originalSortOption == .ascending {
            option = .unreadAscending
        }
        
        sorting = option
        
        super.viewDidLoad()
        
    }

    deinit {
        
        if originalSortOption != sorting,
           Defaults[.feedSorting] != originalSortOption.rawValue {
            
            Defaults[.feedSorting] = originalSortOption.rawValue
            
        }
        
    }
    
    // MARK: - State
    override var emptyViewDisplayTitle: String {
        return "Unreads"
    }

}
