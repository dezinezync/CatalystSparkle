//
//  FeedInfoCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 02/12/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import UIKit

public let kFeedInfoCell = "com.elytra.cell.feedinfo"

class FeedInfoCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var toggle: UISwitch!
    
    class func register(tableView: UITableView) {
        
        let bundle = Bundle.init(for: FeedInfoCell.self)
        
        let nib: UINib = UINib.init(nibName: "FeedInfoCell", bundle: bundle)
        
        tableView.register(nib, forCellReuseIdentifier: kFeedInfoCell)
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.toggle.removeTarget(nil, action: nil, for: .allEvents)
        self.label.text = nil
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
}
