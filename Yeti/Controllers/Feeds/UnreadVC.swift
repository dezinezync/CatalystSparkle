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
        
        super.viewDidLoad()
        
    }

    // MARK: - State
    override var emptyViewDisplayTitle: String {
        return "Unreads"
    }

}
