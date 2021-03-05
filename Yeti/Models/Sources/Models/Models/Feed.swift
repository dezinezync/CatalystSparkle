//
//  Feed.swift
//  
//
//  Created by Nikhil Nigade on 02/03/21.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public let kFeedSafariReaderMode = "com.elytra.feed.safariReaderMode"
public let kFeedLocalNotifications = "com.elytra.feed.localNotifications"

class Feed: NSObject, Codable, ObservableObject {
    
    var feedID: UInt!
    var summary: String!
    var title: String!
    var url: URL!
    var favicon: URL!
    var extra: FeedMetaData?
    var rpcCount: UInt! = 0
    var lastRPC: Date?
    var hubSubscribed: Bool! = false
    var subscribed: Bool! = false
    var folderID: UInt? = 0
    var localName: String?
    var podcast: Bool! = false
    
    private enum CodingKeys: String, CodingKey {
        case feedID
        case summary
        case title
        case url
        case favicon
        case extra
        case rpcCount
        case lastRPC
        case hubSubscribed
        case subscribed
        case folderID
        case localName
        case podcast
    }
    
    @Published var unread: UInt! = 0
    
    weak var folder: Folder?
    #if os(macOS)
    var faviconImage: NSImage?
    #else
    var faviconImage: UIImage?
    #endif
    
    var canShowExtraLevel: Bool {
        
        guard let extra = extra else {
            return false
        }
        
        return extra.url != nil
        
    }
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    var faviconURI: String {
        return ""
    }
    
    var displayTitle: String {
        return localName ?? title
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "extra", let value = value as? [String: Any] {
            
            let extra = FeedMetaData(from: value)
            
            self.extra = extra
            
        }
        else if key == "title",
                let value = value as? String {
            title = value
        }
        else if key == "rpcCount" {
            
            if let value = value as? UInt {
                rpcCount = value
            }
            
        }
        else if key == "url",
                let value = value as? String {
            
            if let url = URL(string: value) {
                self.url = url
            }
            
        }
        else if key == "favicon",
                let value = value as? String {
            
            if let url = URL(string: value) {
                favicon = url
            }
            
        }
        else if key == "lastRPC" {
            
            if let value = value as? String,
               let date = Subscription.dateFormatter.date(from: value) {
                lastRPC = date
            }
            
        }
        else if key == "hubSubscribed",
                let value = value as? Bool {
            
            hubSubscribed = value
            
        }
        else if key == "podcast",
                let value = value as? Bool {
            
            podcast = value
            
        }
        else {
            
            super.setValue(value, forKey: key)
            
        }
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "feed", let value = value as? [String: Any] {
            
            return setValuesForKeys(value)
            
        }
        else if key == "summary",
                let value = value as? String {
            
            summary = value
            
        }
        else if key == "id", let value = value as? UInt {
            
            feedID = value
            
        }
        else {
            #if DEBUG
            print("Feed undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension Feed {
    
    static func == (lhs: Feed, rhs: Feed) -> Bool {
        
        switch (lhs, rhs) {
        case (lhs, rhs): do {
            return lhs.url == rhs.url && lhs.feedID == rhs.feedID
        }
        default:
            return false
        }
        
    }
    
}

extension Feed: Copyable {}
