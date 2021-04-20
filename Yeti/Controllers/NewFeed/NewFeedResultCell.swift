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

#if !TARGET_IS_EXTENSION
import Models
#endif

@objcMembers class NewFeedResultCell: UITableViewCell {
    
    static let identifer: String = "NewFeedResultCell"
    
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
            frame.origin.y = (contentView.frame.height - 32)/2
            imageView?.frame = frame
            
            if var tframe = textLabel?.frame {
                tframe.origin.x = frame.maxX + 12
                textLabel?.frame = tframe
            }
            
            if var tframe = detailTextLabel?.frame {
                tframe.origin.x = frame.maxX + 12
                detailTextLabel?.frame = tframe
            }
            
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
    
    #if !TARGET_IS_EXTENSION
    func configure(feed: Feed) {
        
        self.textLabel?.text = feed.title
        self.detailTextLabel?.text = feed.url.absoluteString
        
        guard let iconUrl = feed.faviconURI else {
            return
        }
        
        self.imageView?.sd_setImage(with: iconUrl, completed: { [weak self] (image, error, cacheType, url) in
            
            self?.setNeedsLayout()
            
        })
        
    }
    #endif

}

extension NewFeedResultCell {
    
    static func register(_ tableView: UITableView) {
        
        tableView.register(NewFeedResultCell.self, forCellReuseIdentifier: NewFeedResultCell.identifer)
        
    }
    
}
