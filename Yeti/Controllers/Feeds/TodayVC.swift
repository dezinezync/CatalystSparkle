//
//  TodayVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 22/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit

class TodayVC: FeedVC {
    
    override func viewDidLoad() {
        
        type = .today
        
        super.viewDidLoad()
        
    }

    // MARK: - State
    override var emptyViewDisplayTitle: String {
        return "Today"
    }

}
