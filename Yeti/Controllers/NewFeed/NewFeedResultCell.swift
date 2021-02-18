//
//  NewFeedResultCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import FeedsLib
import SDWebImage

class NewFeedResultCell: UITableViewCell {
    
    static let identifer = "NewFeedResultCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        imageView?.layer.cornerRadius = 4
        imageView?.layer.cornerCurve = .continuous
        imageView?.clipsToBounds = true
        imageView?.image = UIImage(systemName: "square.dashed")
        
        textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        
        detailTextLabel?.textColor = .secondaryLabel
        detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        if var frame = imageView?.frame {
            frame.size = CGSize(width: 32, height: 32)
            imageView?.frame = frame
        }
        
    }
    
    func configure(_ item: FeedRecommendation) {
        
        self.textLabel?.text = item.title
        self.detailTextLabel?.text = item.id?.replacingOccurrences(of: "feed/", with: "")
        
        guard let iconUrl = item.iconUrl else {
            return
        }
        
        guard let url = URL(string: iconUrl) else {
            return
        }
        
        self.imageView?.sd_setImage(with: url, completed: { [weak self] (image, error, cacheType, url) in
            
            self?.setNeedsLayout()
            
        })
        
    }

}

extension NewFeedResultCell {
    
    static func register(_ tableView: UITableView) {
        
        tableView.register(NewFeedResultCell.self, forCellReuseIdentifier: NewFeedResultCell.identifer)
        
    }
    
}
